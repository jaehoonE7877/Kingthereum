# Configuration Guide

이 디렉토리는 프로젝트의 API 키와 환경 설정을 관리합니다.

## 🔐 보안 설정 방법

### 1. Development 환경 설정

```bash
# Development.xcconfig를 복사하여 로컬 설정 파일 생성
cp Config/Development.xcconfig Config/Development-Local.xcconfig
```

Development-Local.xcconfig 파일에서 플레이스홀더를 실제 API 키로 교체:

```
// Before
INFURA_PROJECT_ID = YOUR_INFURA_PROJECT_ID_HERE

// After  
INFURA_PROJECT_ID = 5f9de800f1c64d4d99bb37a0bd7badbe
```

### 2. Xcode 프로젝트에 xcconfig 파일 연결

1. Xcode에서 프로젝트를 엽니다
2. 프로젝트 설정 → Info 탭 → Configurations 섹션
3. Debug 설정에 `Development-Local.xcconfig` 연결
4. Release 설정에 `Production.xcconfig` 연결

### 3. 환경변수 사용 (권장)

#### 로컬 개발
```bash
export INFURA_PROJECT_ID="your-actual-project-id"
export INFURA_PROJECT_SECRET="your-actual-secret"
export ETHERSCAN_API_KEY="your-actual-api-key"
```

#### CI/CD 환경
GitHub Actions, Xcode Cloud 등에서 환경변수로 설정

## 📋 필요한 API 키들

### Infura
- 사이트: https://infura.io/
- 필요한 값: Project ID, Project Secret (선택)
- 용도: 이더리움 네트워크 RPC 접근

### Etherscan  
- 사이트: https://etherscan.io/myapikey
- 필요한 값: API Key
- 용도: 트랜잭션 조회, 가스비 정보

## ⚠️ 중요 보안 수칙

1. **절대 API 키를 Git에 커밋하지 마세요**
2. `*-Local.xcconfig` 파일들은 .gitignore에 포함됨
3. 프로덕션 환경에서는 환경변수만 사용
4. API 키는 정기적으로 로테이션
5. 의심스러운 활동 발견 시 즉시 키 무효화