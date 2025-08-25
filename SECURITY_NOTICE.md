# 🚨 보안 알림: 노출된 API 키 처리 가이드

## ⚠️ 노출된 API 키들

다음 API 키가 GitHub public repository에 노출되었습니다:

### Infura Project ID
```
5f9de800f1c64d4d99bb37a0bd7badbe
```

## 🔄 즉시 수행해야 할 보안 조치

### 1. Infura API 키 로테이션

1. **Infura 대시보드 접속**: https://infura.io/dashboard
2. **프로젝트 설정**에서 해당 Project ID 확인
3. **새로운 프로젝트 생성** 또는 **API 키 재생성**
4. **기존 키 비활성화** 또는 **삭제**

### 2. 새로운 API 키 설정

#### 로컬 개발 환경
```bash
# 1. 로컬 설정 파일 생성
cp Config/Development.xcconfig Config/Development-Local.xcconfig

# 2. 새로운 API 키로 교체
# Development-Local.xcconfig 파일에서:
INFURA_PROJECT_ID = 새로운_프로젝트_ID
INFURA_PROJECT_SECRET = 새로운_시크릿 (선택사항)
```

#### 환경변수 방식 (권장)
```bash
export INFURA_PROJECT_ID="새로운_프로젝트_ID"
export INFURA_PROJECT_SECRET="새로운_시크릿"
export ETHERSCAN_API_KEY="새로운_etherscan_키"
```

### 3. Etherscan API 키 설정

Etherscan API 키는 노출되지 않았지만 예방 차원에서 설정:

1. **Etherscan 가입**: https://etherscan.io/myapikey
2. **API 키 생성**
3. **환경변수 또는 로컬 설정 파일에 추가**

## 📋 보안 모니터링

### API 사용량 모니터링
1. **Infura 대시보드**에서 이상 사용량 확인
2. **Etherscan API** 사용 통계 주기적 점검
3. **예상치 못한 트래픽** 발견 시 즉시 키 무효화

### Git 히스토리 정리 (선택사항)
```bash
# ⚠️ 주의: 이는 Git 히스토리를 변경합니다
# 협업 중인 경우 팀과 상의 후 진행

# 민감한 정보가 포함된 커밋 제거 (고급 사용자만)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch ConfigurationService.swift' \
  --prune-empty --tag-name-filter cat -- --all

# 강제 푸시 (위험!)
git push origin --force --all
```

## ✅ 적용된 보안 개선 사항

1. **하드코딩된 API 키 완전 제거**
2. **환경 변수 기반 설정 시스템 구축**
3. **xcconfig 파일을 통한 안전한 개발 환경 제공**
4. **명확한 오류 메시지로 누락된 설정 탐지**
5. **로컬 설정 파일 .gitignore 보호**

## 🔮 향후 보안 계획

1. **정기적인 API 키 로테이션** (3개월마다)
2. **의존성 보안 스캔** (Dependabot 활용)
3. **코드 보안 스캔** (CodeQL 적용)
4. **비밀 정보 스캔** (gitleaks 도구 사용)

## 📞 문의사항

보안 관련 문제나 의문사항이 있으면:
1. GitHub Issues에 **[SECURITY]** 태그로 보고
2. 민감한 보안 취약점은 비공개로 연락

---

**마지막 업데이트**: 2024년 12월 19일  
**상태**: ✅ 보안 조치 완료, API 키 로테이션 필요