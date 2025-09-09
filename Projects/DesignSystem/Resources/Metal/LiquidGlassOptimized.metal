#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

// MARK: - 상수 및 구조체 (최적화됨)

/// 버텍스 입력 구조체
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

/// 버텍스 출력 / 프래그먼트 입력 구조체
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float2 screenCoord;
};

/// 최적화된 유니폼 버퍼 구조체
struct OptimizedLiquidGlassUniforms {
    float4x4 modelViewProjection;  // MVP 매트릭스
    float time;                    // 애니메이션용 시간
    float glassThickness;          // 유리 두께 (0.0-1.0)
    float refractionStrength;      // 굴절 강도 (0.0-1.0)
    float reflectionStrength;      // 반사 강도 (0.0-1.0)
    float distortionStrength;      // 왜곡 강도 (0.0-1.0)
    float noiseScale;              // 노이즈 스케일
    float opacity;                 // 전체 투명도
    float edgeFade;                // 가장자리 페이드 강도
    float2 screenSize;             // 화면 크기
    float3 tintColor;              // 틴트 색상
    float aberrationStrength;      // 색수차 강도
    int qualityLevel;              // 품질 레벨 (0=최소, 3=최고)
    float renderScale;             // 렌더 스케일
};

// MARK: - 최적화된 유틸리티 함수

/// 빠른 해시 함수 (GPU 친화적)
float fastHash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/// 최적화된 단순 노이즈 (Perlin 노이즈 대체)
float fastNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    // 코사인 보간 대신 스무스스텝 사용 (더 빠름)
    f = f * f * (3.0 - 2.0 * f);
    
    float a = fastHash(i);
    float b = fastHash(i + float2(1.0, 0.0));
    float c = fastHash(i + float2(0.0, 1.0));
    float d = fastHash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// 품질 레벨에 따른 적응형 노이즈
float adaptiveNoise(float2 coord, float scale, int qualityLevel) {
    coord *= scale;
    
    switch (qualityLevel) {
        case 3: // 최고 품질: 4-옥타브 FBM
            return (fastNoise(coord) * 0.5 + 
                    fastNoise(coord * 2.0) * 0.25 + 
                    fastNoise(coord * 4.0) * 0.125 + 
                    fastNoise(coord * 8.0) * 0.0625);
        case 2: // 높은 품질: 3-옥타브 FBM
            return (fastNoise(coord) * 0.5 + 
                    fastNoise(coord * 2.0) * 0.25 + 
                    fastNoise(coord * 4.0) * 0.25);
        case 1: // 보통 품질: 2-옥타브
            return (fastNoise(coord) * 0.6 + 
                    fastNoise(coord * 2.0) * 0.4);
        default: // 최소 품질: 단일 옥타브
            return fastNoise(coord);
    }
}

/// 최적화된 가장자리 감지
float fastEdgeFactor(float2 coord, float fadeWidth) {
    float2 edge = abs(coord - 0.5) * 2.0;
    float maxEdge = max(edge.x, edge.y);
    return 1.0 - smoothstep(1.0 - fadeWidth, 1.0, maxEdge);
}

/// 빠른 프레넬 근사
float fastFresnel(float3 viewDir, float3 normal, float power) {
    return pow(1.0 - saturate(dot(viewDir, normal)), power);
}

// MARK: - 버텍스 셰이더 (동일)

vertex VertexOut optimizedLiquidGlassVertex(VertexIn in [[stage_in]],
                                           constant OptimizedLiquidGlassUniforms &uniforms [[buffer(0)]]) {
    VertexOut out;
    
    out.position = uniforms.modelViewProjection * float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    
    // 스크린 좌표 계산
    out.screenCoord = (out.position.xy / out.position.w) * 0.5 + 0.5;
    out.screenCoord.y = 1.0 - out.screenCoord.y;
    
    return out;
}

// MARK: - 최적화된 프래그먼트 셰이더

fragment float4 optimizedLiquidGlassFragment(VertexOut in [[stage_in]],
                                            constant OptimizedLiquidGlassUniforms &uniforms [[buffer(0)]],
                                            texture2d<float> backgroundTexture [[texture(0)]],
                                            sampler textureSampler [[sampler(0)]]) {
    
    float2 uv = in.texCoord;
    float2 screenUV = in.screenCoord;
    
    // 렌더 스케일 적용으로 해상도 조정
    screenUV = screenUV * uniforms.renderScale + (1.0 - uniforms.renderScale) * 0.5;
    
    // MARK: - 적응형 노이즈 생성
    
    // 품질 레벨에 따라 노이즈 복잡도 조정
    float primaryNoise = adaptiveNoise(uv + uniforms.time * 0.1, uniforms.noiseScale, uniforms.qualityLevel);
    
    float secondaryNoise = 0.0;
    if (uniforms.qualityLevel >= 2) {
        secondaryNoise = adaptiveNoise(uv * 2.0 + uniforms.time * 0.15, uniforms.noiseScale * 0.5, uniforms.qualityLevel - 1);
    }
    
    float combinedNoise = mix(primaryNoise, secondaryNoise, 0.3);
    
    // MARK: - 최적화된 굴절 효과
    
    // 품질 레벨에 따른 굴절 샘플링
    float2 refractionOffset = float2(0.0);
    
    if (uniforms.qualityLevel >= 1) {
        float2 noiseGrad = float2(
            adaptiveNoise(uv + float2(0.01, 0.0), uniforms.noiseScale * 2.0, min(uniforms.qualityLevel, 2)) - 
            adaptiveNoise(uv - float2(0.01, 0.0), uniforms.noiseScale * 2.0, min(uniforms.qualityLevel, 2)),
            adaptiveNoise(uv + float2(0.0, 0.01), uniforms.noiseScale * 2.0, min(uniforms.qualityLevel, 2)) - 
            adaptiveNoise(uv - float2(0.0, 0.01), uniforms.noiseScale * 2.0, min(uniforms.qualityLevel, 2))
        );
        
        refractionOffset = noiseGrad * uniforms.refractionStrength * uniforms.glassThickness * 0.015;
        
        // 가장자리에서 굴절 감소
        float edgeMask = fastEdgeFactor(uv, 0.1);
        refractionOffset *= edgeMask;
    }
    
    // MARK: - 색수차 (고품질에서만 적용)
    
    float4 refractedColor;
    
    if (uniforms.qualityLevel >= 3 && uniforms.aberrationStrength > 0.001) {
        // 색수차 적용
        float aberration = uniforms.aberrationStrength * 0.003;
        float2 redOffset = screenUV + refractionOffset + float2(aberration, 0.0);
        float2 greenOffset = screenUV + refractionOffset;
        float2 blueOffset = screenUV + refractionOffset - float2(aberration, 0.0);
        
        refractedColor.r = backgroundTexture.sample(textureSampler, redOffset).r;
        refractedColor.g = backgroundTexture.sample(textureSampler, greenOffset).g;
        refractedColor.b = backgroundTexture.sample(textureSampler, blueOffset).b;
        refractedColor.a = 1.0;
    } else {
        // 단순 굴절 (성능 최적화)
        refractedColor = backgroundTexture.sample(textureSampler, screenUV + refractionOffset);
    }
    
    // MARK: - 최적화된 반사 효과
    
    float fresnel = 0.2; // 기본값
    float3 reflectionColor = uniforms.tintColor;
    
    if (uniforms.qualityLevel >= 2 && uniforms.reflectionStrength > 0.1) {
        // 고품질: 실제 프레넬 계산
        float2 normal = float2(
            primaryNoise - adaptiveNoise(uv + float2(0.02, 0.0), uniforms.noiseScale, 1),
            primaryNoise - adaptiveNoise(uv + float2(0.0, 0.02), uniforms.noiseScale, 1)
        );
        
        float3 viewDir = float3(0.0, 0.0, 1.0);
        float3 surfaceNormal = normalize(float3(normal * 0.1, 1.0));
        fresnel = fastFresnel(viewDir, surfaceNormal, 2.0);
        
        // 환경 반사 색상 (시간에 따라 변화)
        reflectionColor = mix(
            float3(0.85, 0.9, 1.0),   // 차가운 톤
            float3(1.0, 0.9, 0.8),    // 따뜻한 톤
            (sin(uniforms.time * 0.3) + 1.0) * 0.5
        );
    } else if (uniforms.qualityLevel >= 1) {
        // 중간 품질: 단순화된 프레넬
        fresnel = 0.1 + 0.8 * (1.0 - dot(normalize(float3(uv - 0.5, 1.0)), float3(0.0, 0.0, 1.0)));
    }
    
    // MARK: - 유리 표면 효과 (최적화)
    
    float glassDepth = uniforms.glassThickness * (0.9 + 0.1 * combinedNoise);
    float3 glassColor = uniforms.tintColor * (0.95 + 0.05 * sin(uniforms.time + combinedNoise * 6.28));
    
    // 단순화된 흡수 효과
    float3 absorptionColor = exp(-glassColor * glassDepth * 1.5);
    
    // MARK: - 최종 색상 조합 (최적화)
    
    float3 finalColor = refractedColor.rgb * absorptionColor;
    
    // 반사 추가
    finalColor = mix(finalColor, reflectionColor, fresnel * uniforms.reflectionStrength);
    
    // 유리 고유 색상 블렌딩 (품질에 따라 조정)
    float glassTint = 0.05 * uniforms.glassThickness;
    if (uniforms.qualityLevel >= 2) {
        glassTint *= (1.0 + 0.2 * combinedNoise);
    }
    finalColor = mix(finalColor, glassColor, glassTint);
    
    // 스펙큘러 하이라이트 (고품질에서만)
    if (uniforms.qualityLevel >= 2) {
        float specular = pow(max(0.0, combinedNoise), 12.0) * fresnel;
        finalColor += specular * 0.2;
    }
    
    // MARK: - 가장자리 효과 (최적화)
    
    float edgeEffect = 1.0;
    if (uniforms.edgeFade > 0.01) {
        edgeEffect = fastEdgeFactor(uv, uniforms.edgeFade);
        
        // 고품질에서만 가장자리 글로우 적용
        if (uniforms.qualityLevel >= 2) {
            float edgeGlow = 1.0 - edgeEffect;
            edgeGlow = pow(edgeGlow, 3.0) * 0.2;
            finalColor += edgeGlow * uniforms.tintColor;
        }
    }
    
    // 최종 투명도 계산 (성능 최적화)
    float finalOpacity = uniforms.opacity * edgeEffect;
    
    // 고품질에서만 노이즈 기반 투명도 변화
    if (uniforms.qualityLevel >= 3) {
        finalOpacity *= (0.85 + 0.15 * combinedNoise);
    }
    
    return float4(finalColor, finalOpacity);
}

// MARK: - 초경량 셰이더 (최소 품질용)

fragment float4 minimalLiquidGlassFragment(VertexOut in [[stage_in]],
                                          constant OptimizedLiquidGlassUniforms &uniforms [[buffer(0)]],
                                          texture2d<float> backgroundTexture [[texture(0)]],
                                          sampler textureSampler [[sampler(0)]]) {
    
    float2 uv = in.texCoord;
    float2 screenUV = in.screenCoord;
    
    // 매우 단순한 노이즈
    float noise = fastNoise(uv * uniforms.noiseScale + uniforms.time * 0.1);
    
    // 최소한의 굴절 효과
    float2 offset = (noise - 0.5) * uniforms.refractionStrength * 0.005;
    float4 refracted = backgroundTexture.sample(textureSampler, screenUV + offset);
    
    // 단순한 유리 효과
    float3 tinted = refracted.rgb * uniforms.tintColor;
    tinted = mix(refracted.rgb, tinted, uniforms.glassThickness * 0.1);
    
    // 가장자리 페이드
    float edge = fastEdgeFactor(uv, 0.1);
    float opacity = uniforms.opacity * edge;
    
    return float4(tinted, opacity);
}