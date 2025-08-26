#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

// MARK: - 상수 및 구조체

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

/// 유니폼 버퍼 구조체
struct LiquidGlassUniforms {
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
};

// MARK: - 유틸리티 함수

/// 패린 노이즈 함수
float perlinNoise(float2 coord, float scale) {
    coord *= scale;
    float2 i = floor(coord);
    float2 f = fract(coord);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = dot(sin(i * 12.9898 + float2(78.233, 56.787)), float2(43758.5453));
    float b = dot(sin((i + float2(1.0, 0.0)) * 12.9898 + float2(78.233, 56.787)), float2(43758.5453));
    float c = dot(sin((i + float2(0.0, 1.0)) * 12.9898 + float2(78.233, 56.787)), float2(43758.5453));
    float d = dot(sin((i + float2(1.0, 1.0)) * 12.9898 + float2(78.233, 56.787)), float2(43758.5453));
    
    a = fract(sin(a) * 43758.5453);
    b = fract(sin(b) * 43758.5453);
    c = fract(sin(c) * 43758.5453);
    d = fract(sin(d) * 43758.5453);
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// 다층 노이즈 (Fractal Brownian Motion)
float fbmNoise(float2 coord, int octaves, float scale) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * perlinNoise(coord, scale);
        coord *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

/// 가장자리 감지 함수
float edgeFactor(float2 coord, float fadeWidth) {
    float2 edge = abs(coord - 0.5) * 2.0;
    float maxEdge = max(edge.x, edge.y);
    return 1.0 - smoothstep(1.0 - fadeWidth, 1.0, maxEdge);
}

// MARK: - 버텍스 셰이더

vertex VertexOut liquidGlassVertex(VertexIn in [[stage_in]],
                                   constant LiquidGlassUniforms &uniforms [[buffer(0)]]) {
    VertexOut out;
    
    // 정점 변환
    out.position = uniforms.modelViewProjection * float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    
    // 스크린 좌표 계산 (NDC에서 스크린 좌표로)
    out.screenCoord = (out.position.xy / out.position.w) * 0.5 + 0.5;
    out.screenCoord.y = 1.0 - out.screenCoord.y; // Y축 뒤집기
    
    return out;
}

// MARK: - 프래그먼트 셰이더

fragment float4 liquidGlassFragment(VertexOut in [[stage_in]],
                                    constant LiquidGlassUniforms &uniforms [[buffer(0)]],
                                    texture2d<float> backgroundTexture [[texture(0)]],
                                    texture2d<float> noiseTexture [[texture(1)]],
                                    sampler textureSampler [[sampler(0)]]) {
    
    float2 uv = in.texCoord;
    float2 screenUV = in.screenCoord;
    
    // MARK: - 노이즈 생성
    
    // 다양한 스케일의 노이즈 조합
    float noise1 = fbmNoise(uv + uniforms.time * 0.1, 4, uniforms.noiseScale);
    float noise2 = fbmNoise(uv * 2.0 + uniforms.time * 0.15, 3, uniforms.noiseScale * 0.5);
    float noise3 = perlinNoise(uv * 4.0 + uniforms.time * 0.05, uniforms.noiseScale * 2.0);
    
    // 노이즈 조합
    float combinedNoise = (noise1 * 0.6 + noise2 * 0.3 + noise3 * 0.1);
    
    // MARK: - 굴절 효과
    
    // 굴절 벡터 계산 (노이즈 기반)
    float2 refractionOffset = float2(
        fbmNoise(uv + float2(uniforms.time * 0.1, 0.0), 3, uniforms.noiseScale * 3.0),
        fbmNoise(uv + float2(0.0, uniforms.time * 0.12), 3, uniforms.noiseScale * 3.0)
    ) - 0.5;
    
    refractionOffset *= uniforms.refractionStrength * uniforms.glassThickness * 0.02;
    
    // 가장자리에서 굴절 감소
    float edgeMask = edgeFactor(uv, 0.1);
    refractionOffset *= edgeMask;
    
    // MARK: - 색수차 (Chromatic Aberration)
    
    float aberration = uniforms.aberrationStrength * 0.005;
    float2 redOffset = screenUV + refractionOffset + float2(aberration, 0.0);
    float2 greenOffset = screenUV + refractionOffset;
    float2 blueOffset = screenUV + refractionOffset - float2(aberration, 0.0);
    
    // 배경 텍스처 샘플링 (색수차 적용)
    float4 refractedColor;
    refractedColor.r = backgroundTexture.sample(textureSampler, redOffset).r;
    refractedColor.g = backgroundTexture.sample(textureSampler, greenOffset).g;
    refractedColor.b = backgroundTexture.sample(textureSampler, blueOffset).b;
    refractedColor.a = 1.0;
    
    // MARK: - 반사 효과
    
    // 프레넬 효과 계산
    float2 normal = normalize(float2(
        fbmNoise(uv + float2(0.01, 0.0), 2, uniforms.noiseScale * 5.0) - 
        fbmNoise(uv - float2(0.01, 0.0), 2, uniforms.noiseScale * 5.0),
        fbmNoise(uv + float2(0.0, 0.01), 2, uniforms.noiseScale * 5.0) - 
        fbmNoise(uv - float2(0.0, 0.01), 2, uniforms.noiseScale * 5.0)
    ));
    
    // 뷰 방향 (단순화)
    float3 viewDir = float3(0.0, 0.0, 1.0);
    float3 surfaceNormal = normalize(float3(normal * 0.1, 1.0));
    
    // 프레넬 항
    float fresnel = pow(1.0 - abs(dot(viewDir, surfaceNormal)), 2.0);
    fresnel = mix(0.1, 0.9, fresnel);
    
    // 반사 색상 (환경광 시뮬레이션)
    float3 reflectionColor = mix(
        float3(0.9, 0.95, 1.0),  // 차가운 톤
        float3(1.0, 0.95, 0.8),  // 따뜻한 톤
        (sin(uniforms.time * 0.5) + 1.0) * 0.5
    );
    
    // MARK: - 유리 표면 효과
    
    // 유리 내부 밀도 변화 시뮬레이션
    float glassDepth = uniforms.glassThickness * (0.8 + 0.2 * combinedNoise);
    
    // 유리 색상 (약간의 청록색 틴트)
    float3 glassColor = uniforms.tintColor * (0.95 + 0.1 * sin(uniforms.time + combinedNoise * 6.28));
    
    // 두께에 따른 색상 흡수
    float3 absorptionColor = exp(-glassColor * glassDepth * 2.0);
    
    // MARK: - 최종 색상 조합
    
    // 굴절된 배경과 유리 색상 혼합
    float3 finalColor = refractedColor.rgb * absorptionColor;
    
    // 반사 추가
    finalColor = mix(finalColor, reflectionColor, fresnel * uniforms.reflectionStrength);
    
    // 유리 고유 색상 블렌딩
    finalColor = mix(finalColor, glassColor, 0.1 * uniforms.glassThickness);
    
    // 하이라이트 추가 (유리 표면의 스펙큘러)
    float specular = pow(max(0.0, combinedNoise), 16.0) * fresnel;
    finalColor += specular * 0.3;
    
    // MARK: - 가장자리 효과
    
    // 가장자리 글로우 효과
    float edgeGlow = 1.0 - edgeFactor(uv, uniforms.edgeFade);
    edgeGlow = pow(edgeGlow, 2.0) * 0.3;
    finalColor += edgeGlow * uniforms.tintColor;
    
    // 최종 투명도 계산
    float finalOpacity = uniforms.opacity * edgeFactor(uv, 0.05);
    finalOpacity *= (0.8 + 0.2 * combinedNoise); // 노이즈로 약간의 변화
    
    return float4(finalColor, finalOpacity);
}