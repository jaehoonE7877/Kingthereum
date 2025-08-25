# 👑 Kingthereum

[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Swift%20(VIP)-green.svg)](https://clean-swift.com)
[![Tuist](https://img.shields.io/badge/Tuist-4.48.1-purple.svg)](https://tuist.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**SwiftUI와 Clean Swift 아키텍처로 구축된 아름답고 안전하며 사용자 친화적인 Ethereum 지갑입니다.**

> *Glassmorphism UI 디자인과 엔터프라이즈급 보안으로 Ethereum blockchain의 힘을 경험하세요.*

## ✨ 주요 기능

🔐 **은행 수준의 보안**
- 생체 인증 (Face ID, Touch ID, Optic ID)
- Hardware 기반 Keychain 저장소
- Secure Enclave를 활용한 PIN 보호

💎 **Glassmorphism UI 디자인**
- 현대적인 시각 효과의 액체 유리 미학
- iOS 17+, iPadOS 17+, macOS 14+ Native 지원
- 아름다운 Gradient와 Dark Mode 최적화

⚡ **완전한 Ethereum 통합**
- Web3.swift 기반 Mainnet 지원
- ERC-20 Token 호환성
- 스마트 Gas Fee 최적화
- 완전한 Transaction 내역 추적

🏗 **Enterprise 아키텍처**
- 테스트 가능한 Clean Swift (VIP) Pattern
- 5개 모듈로 구성된 모듈화 설계
- 포괄적인 Unit Test Coverage
- Factory를 활용한 Dependency Injection

## 🚀 빠른 시작

### 사전 요구사항
- **Xcode 16.0+** 
- **macOS 14.0+** (개발 환경)
- **Tuist 4.48.1** (프로젝트 생성)

### 설치 방법

```bash
# 1. Tuist 설치
curl -Ls https://install.tuist.io | bash

# 2. 프로젝트 Clone 및 이동
git clone https://github.com/your-username/Kingthereum.git
cd Kingthereum

# 3. Dependency 설치 및 프로젝트 생성
tuist install
tuist generate

# 4. Workspace 열기
open Kingthereum.xcworkspace
```

### 설정

1. `Projects/Core/Sources/Models/Network.swift`에서 Ethereum Node URL 추가
2. `YOUR_PROJECT_ID`를 실제 [Infura](https://infura.io) 또는 [Alchemy](https://alchemy.com) Project ID로 교체
3. **⌘ + R**로 빌드 및 실행

## 🧪 테스트

```bash
# 모든 테스트 실행
tuist test

# Unit Test만 실행
tuist test --skip-ui-tests
```

**테스트 커버리지:**
- ✅ Core 비즈니스 로직
- ✅ Security Component들
- ✅ Wallet 작업
- ✅ VIP Pattern 구현체

## 📦 아키텍처

### 모듈 구조
```
Kingthereum/
├── App/           # 메인 Application & Scene (VIP Pattern)
├── Core/          # 비즈니스 로직 & Utility
├── WalletKit/     # Ethereum & Web3 통합  
├── SecurityKit/   # 인증 & Keychain
└── DesignSystem/  # Glassmorphism UI Component
```

### 기술 스택

**핵심 기술:**
- **Swift 6.0** with Strict Concurrency
- **SwiftUI** 선언형 UI
- **Combine** Reactive Programming

**주요 Dependency:**
- **web3swift** `3.2.0` - Ethereum Blockchain 통합
- **KeychainAccess** `4.2.2` - 보안 저장소
- **Factory** `2.5.3` - Dependency Injection

**개발 도구:**
- **Tuist** - 프로젝트 생성 & 모듈화
- **Swift Testing** - 현대적 테스트 Framework

## 🛡 보안 기능

- Private Key가 기기를 벗어나지 않음
- 모든 민감한 데이터는 iOS Keychain으로 암호화
- 지갑 접근을 위한 생체 인증
- Hardware 보안 기반 Transaction 서명
- PIN 백업 인증 시스템

## 🌍 지원 플랫폼

- **iOS** 17.0+
- **iPadOS** 17.0+  
- **macOS** 14.0+ (Catalyst)

## 🤝 기여하기

1. Repository Fork
2. [Git Convention](CLAUDE.md#git-에티켓)을 따라 Feature Branch 생성
3. Clean Swift 아키텍처 패턴 준수
4. 포괄적인 Unit Test 추가
5. 문서 업데이트
6. Pull Request 제출

## 📄 문서

- [Architecture Guide](Architecture.md) - 상세한 시스템 설계
- [Development Guidelines](CLAUDE.md) - 코드 표준 & Pattern
- [Security Notice](SECURITY_NOTICE.md) - 보안 고려사항
- [Testing Guide](TESTING.md) - 테스트 전략

## 📝 라이선스

이 프로젝트는 MIT License 하에 배포됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- 훌륭한 Web3.swift Library를 제공한 [web3swift team](https://github.com/web3swift-team/web3swift)
- VIP 아키텍처 Pattern을 위한 [Clean Swift](https://clean-swift.com/)
- 현대적인 iOS 프로젝트 관리를 위한 [Tuist](https://tuist.io/)

---

**SwiftUI, Clean Swift & Tuist로 ❤️를 담아 만들었습니다**

*Kingthereum - 당신의 Ethereum 왕관* 👑