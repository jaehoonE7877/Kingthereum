# 👑 Kingthereum

**당신의 이더리움 왕관** - SwiftUI와 Clean Swift 아키텍처로 구축된 아름답고 안전하며 사용자 친화적인 이더리움 지갑입니다.

## 🚀 이 앱은 무엇인가요?

Kingthereum은 iOS에서 이더리움 블록체인을 안전하고 쉽게 사용할 수 있도록 만든 지갑 앱입니다. 복잡한 암호화폐 거래를 간단하고 아름다운 인터페이스로 경험할 수 있습니다.

### 🎯 누구를 위한 앱인가요?
- 암호화폐를 처음 접하는 초보자
- 안전하고 아름다운 지갑을 원하는 사용자
- iOS 개발을 공부하고 있는 개발자
- 최신 SwiftUI 기술을 배우고 싶은 분들

## ✨ 주요 기능

### 🔐 보안 우선
- **생체 인증**: Face ID, Touch ID, Optic ID 지원으로 안전한 로그인
- **PIN 보호**: 4-8자리 PIN으로 이중 보안
- **키체인 저장**: iOS 키체인에 개인키를 안전하게 보관
- **하드웨어 보안**: Secure Enclave 활용으로 최고 수준의 보안

### 💎 아름다운 UI
- **액체 유리 디자인**: 최신 글래스모피즘 UI로 시각적 즐거움 제공
- **멀티 플랫폼**: iOS 17+, iPadOS 17+, macOS 14+ 네이티브 지원
- **다크 모드 최적화**: 아름다운 그라데이션과 유리 효과
- **반응형 레이아웃**: 모든 화면 크기에 완벽 적응

### ⚡ 이더리움 연동
- **메인넷 지원**: 실제 이더리움 네트워크 완전 호환
- **ERC-20 토큰**: 모든 표준 이더리움 토큰 지원
- **Web3.swift**: 안정적인 Web3 라이브러리 기반
- **가스비 최적화**: 스마트한 가스비 예측과 최적화
- **거래 내역**: 완전한 거래 추적 및 기록

### 🏗 개발 아키텍처
- **Clean Swift (VIP)**: 테스트 가능하고 유지보수 쉬운 구조
- **모듈형 설계**: Core, Security, Wallet, Design 모듈 분리
- **Tuist**: 현대적인 프로젝트 생성 및 의존성 관리
- **단위 테스트**: 비즈니스 로직 전반에 걸친 테스트 커버리지

## 📁 프로젝트 구조

```
Kingthereum/
├── Tuist.swift                    # Tuist 설정 파일
├── Workspace.swift                 # 워크스페이스 정의
├── Tuist/
│   ├── Package.swift              # 외부 라이브러리 의존성
│   └── ProjectDescriptionHelpers/ # 재사용 가능한 헬퍼들
├── Projects/
│   ├── App/                      # 메인 앱
│   ├── Core/                     # 핵심 비즈니스 로직
│   ├── WalletKit/                # 이더리움 & Web3 연동
│   ├── SecurityKit/              # 보안 & 인증
│   └── DesignSystem/             # 액체 유리 UI 컴포넌트
```

### 📦 모듈 상세 설명

#### **🎯 App 모듈**
- 앱의 진입점 및 메인 실행 부분
- Clean Swift 아키텍처 (VIP 패턴) 적용
- 화면 간 내비게이션 및 라우팅
- 앱 생명주기 관리

#### **⚙️ Core 모듈**
- 데이터 모델들 (지갑, 거래, 토큰, 네트워크)
- 비즈니스 로직 인터페이스
- 상수값들과 유틸리티 함수들
- 포매터와 Swift 확장 기능들

#### **💰 WalletKit 모듈**
- 이더리움 블록체인 연동 기능
- Web3.swift 라이브러리 래퍼
- 거래 처리 및 검증
- 토큰 관리 (ETH + ERC-20)
- 가스비 예측 및 최적화

#### **🔒 SecurityKit 모듈**
- 생체 인증 (Face ID, Touch ID)
- PIN 번호 관리
- iOS 키체인 연동
- 안전한 데이터 저장

#### **🎨 DesignSystem 모듈**
- 액체 유리 효과 UI 컴포넌트들
- 커스텀 타이포그래피
- 앱 전용 컬러 시스템
- 애니메이션과 시각 효과

## 🚀 시작하기

### 🛠 필요한 것들

- **Xcode 15.0 이상**: 애플 개발 도구
- **iOS 17.0+ / iPadOS 17.0+ / macOS 14.0+**: 지원 플랫폼
- **Tuist 4.0 이상**: 프로젝트 관리 도구

### 📲 설치 방법

#### 1단계: Tuist 설치
```bash
# 간단 설치 (추천)
curl -Ls https://install.tuist.io | bash

# 또는 Homebrew로 설치
brew install tuist
```

#### 2단계: 프로젝트 폴더로 이동
```bash
cd /Users/jaehoonseo/Desktop/Kingthereum
```

#### 3단계: 의존성 설치
```bash
# 외부 라이브러리들을 자동으로 다운로드
tuist install
```

#### 4단계: 프로젝트 생성
```bash
# Xcode 프로젝트 파일들 생성
tuist generate
```

#### 5단계: Xcode에서 열기
```bash
# 워크스페이스 열기
open Kingthereum.xcworkspace
```

### ⚙️ 추가 설정

#### 이더리움 노드 설정
1. `Projects/Core/Sources/Models/Network.swift` 파일 열기
2. `YOUR_PROJECT_ID` 부분을 실제 Infura 또는 Alchemy 프로젝트 ID로 변경
3. 무료 계정은 [Infura](https://infura.io) 또는 [Alchemy](https://alchemy.com)에서 생성 가능

#### 빌드 및 실행
1. Xcode에서 타겟 플랫폼 선택 (iPhone, iPad, Mac)
2. **⌘ + R** 키를 눌러 빌드 및 실행

## 🧪 테스트 실행

### 터미널에서 테스트
```bash
# 모든 테스트 실행
tuist test
```

### Xcode에서 테스트
- **⌘ + U**: 단위 테스트 실행
- **⌘ + Ctrl + U**: UI 테스트 실행

### 📊 테스트 커버리지

현재 다음 모듈들에 대한 테스트가 구현되어 있습니다:

- **✅ Core 모듈**: 데이터 모델, 포매터, 유틸리티
- **✅ SecurityKit**: 인증 및 PIN 관리
- **✅ WalletKit**: Web3 연동 및 거래 로직
- **✅ Authentication 화면**: 완전한 VIP 사이클 테스트

## 🏛 아키텍처 상세 설명

### 📋 Clean Swift (VIP) 패턴

각 화면은 VIP 아키텍처를 따릅니다:

```
ViewController → Interactor → Presenter → ViewController
     ↓             ↓           ↓
   요청         비즈니스      응답
   모델          로직        모델
```

### 🔄 데이터 흐름

1. **사용자 상호작용** → ViewController가 사용자 입력을 받음
2. **요청 생성** → ViewController가 요청을 만들어 Interactor에 전달
3. **비즈니스 로직** → Interactor가 Worker를 사용해 요청 처리
4. **응답 전달** → Interactor가 결과를 Presenter에 전달
5. **프레젠테이션** → Presenter가 응답을 ViewModel로 변환
6. **화면 업데이트** → ViewController가 ViewModel로 UI 업데이트

### 🛡 보안 아키텍처

```
사용자 인증 요청
    ↓
생체/PIN 인증 확인
    ↓
키체인 접근 권한 획득
    ↓
개인키 안전 추출
    ↓
Web3 거래 서명
```

### 💡 왜 이런 구조를 선택했나요?

- **테스트 용이성**: 각 계층이 분리되어 단위 테스트가 쉬움
- **유지보수성**: 코드가 명확하게 분리되어 수정이 간편
- **확장성**: 새로운 기능 추가가 기존 코드에 영향을 주지 않음
- **재사용성**: 각 모듈을 다른 프로젝트에서도 활용 가능

## 📱 지원 플랫폼

- **iOS**: 17.0 이상
- **iPadOS**: 17.0 이상  
- **macOS**: 14.0 이상

## 🔒 보안 기능

- 개인키가 기기를 벗어나지 않음
- 생체 인증 (Face ID, Touch ID, Optic ID)
- PIN 기반 백업 인증
- 하드웨어 보안과 키체인 연동
- 거래 확인 플로우
- Secure Enclave 활용

## 🎨 디자인 시스템

### 💧 액체 유리 컴포넌트들

- **GlassCard**: 글래스모피즘 효과가 있는 컨테이너
- **GlassButton**: 유리 스타일의 인터랙티브 버튼
- **GlassTextField**: 유리 미학을 적용한 입력 필드
- **Typography**: 둥근 디자인의 커스텀 폰트 시스템
- **Colors**: 그라데이션이 포함된 왕실 컬러 팔레트

### 🎨 테마 컬러

- **킹 블루**: `rgb(51, 102, 230)`
- **킹 퍼플**: `rgb(128, 51, 204)`
- **킹 골드**: `rgb(230, 179, 51)`
- **이더리움 블루**: `rgb(97, 189, 252)`

## 🤝 기여하기

1. 레포지토리를 포크하세요
2. 기능 브랜치를 생성하세요
3. Clean Swift 아키텍처 패턴을 따라주세요
4. 포괄적인 테스트를 추가하세요
5. 문서를 업데이트하세요
6. 풀 리퀘스트를 제출하세요

### 📝 코드 스타일

- Swift API 디자인 가이드라인을 따르세요
- 새로운 화면에는 Clean Swift (VIP) 사용
- 모듈형 아키텍처를 유지하세요
- 비즈니스 로직에 대한 단위 테스트 작성
- 공개 API 문서화

## 🛠 사용된 기술 스택

### 📚 주요 라이브러리
- **web3swift**: 이더리움 블록체인 연동
- **KeychainAccess**: 안전한 키체인 저장소
- **SwiftUIIntrospect**: SwiftUI 고급 기능

### 🔧 개발 도구
- **Tuist**: 프로젝트 관리 및 의존성 관리
- **Swift 5.9**: 최신 Swift 언어 기능
- **SwiftUI**: 선언형 UI 프레임워크
- **Combine**: 반응형 프로그래밍

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- [web3swift 팀](https://github.com/web3swift-team/web3swift)의 훌륭한 Web3.swift 라이브러리
- [Clean Swift](https://clean-swift.com/)의 VIP 아키텍처 패턴
- [Tuist](https://tuist.io/)의 현대적인 iOS 프로젝트 관리

## 🐛 문제 신고 & 지원

버그를 발견하거나 도움이 필요하신가요? GitHub에서 이슈를 열어주세요.

---

**❤️로 만들어진 SwiftUI, Clean Swift, Tuist 기반 앱**

*Kingthereum - 당신의 이더리움 왕관* 👑