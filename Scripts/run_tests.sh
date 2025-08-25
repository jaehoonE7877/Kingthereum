#!/bin/bash

# Kingthereum iOS 프로젝트 Swift Testing 실행 스크립트
# iOS 17+ 및 Xcode 16+ 의 Swift Testing framework를 사용한 포괄적 테스트 실행

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 프로젝트 설정
PROJECT_NAME="Kingthereum"
WORKSPACE_PATH="$PROJECT_NAME.xcworkspace"
SCHEME_PREFIX="$PROJECT_NAME"

# 테스트할 모듈들
MODULES=("Core" "SecurityKit" "WalletKit")

# iOS 시뮬레이터 설정 (iOS 17.0+)
SIMULATOR_NAME="iPhone 15 Pro"
IOS_VERSION="17.0"
DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME,OS=$IOS_VERSION"

# 로그 함수들
log_header() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${WHITE}========================================${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_module() {
    echo -e "${PURPLE}[MODULE]${NC} $1"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# 전제 조건 확인
check_prerequisites() {
    log_header "전제 조건 확인"
    
    # Xcode 버전 확인
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode가 설치되어 있지 않습니다."
        exit 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -n 1 | sed 's/Xcode //')
    log_info "Xcode 버전: $xcode_version"
    
    # Xcode 16+ 확인 (Swift Testing을 위해)
    local major_version=$(echo $xcode_version | cut -d. -f1)
    if [ "$major_version" -lt 16 ]; then
        log_warning "Swift Testing을 위해서는 Xcode 16 이상이 권장됩니다. 현재 버전: $xcode_version"
    fi
    
    # Tuist 확인
    if ! command -v tuist &> /dev/null; then
        log_error "Tuist가 설치되어 있지 않습니다."
        exit 1
    fi
    
    local tuist_version=$(tuist version)
    log_info "Tuist 버전: $tuist_version"
    
    # 워크스페이스 확인
    if [ ! -d "$WORKSPACE_PATH" ]; then
        log_warning "워크스페이스를 찾을 수 없습니다. Tuist 프로젝트를 생성합니다..."
        tuist generate
    fi
    
    log_success "전제 조건 확인 완료"
}

# 시뮬레이터 확인 및 부팅
setup_simulator() {
    log_header "시뮬레이터 설정"
    
    # 사용 가능한 시뮬레이터 확인
    local simulator_udid=$(xcrun simctl list devices "$SIMULATOR_NAME" | grep -E "iOS $IOS_VERSION" | head -n 1 | grep -o "[A-F0-9-]\{36\}")
    
    if [ -z "$simulator_udid" ]; then
        log_error "시뮬레이터를 찾을 수 없습니다: $SIMULATOR_NAME (iOS $IOS_VERSION)"
        log_info "사용 가능한 시뮬레이터:"
        xcrun simctl list devices available
        exit 1
    fi
    
    log_info "시뮬레이터 UDID: $simulator_udid"
    
    # 시뮬레이터 부팅
    local boot_status=$(xcrun simctl list devices | grep "$simulator_udid" | grep -o "Booted\|Shutdown")
    if [ "$boot_status" != "Booted" ]; then
        log_info "시뮬레이터를 부팅합니다..."
        xcrun simctl boot "$simulator_udid"
        sleep 5
    fi
    
    log_success "시뮬레이터 설정 완료"
}

# 개별 모듈 테스트 실행
run_module_tests() {
    local module=$1
    local scheme="${module}Tests"
    
    log_module "테스트 실행: $module"
    
    # Swift Testing을 사용한 테스트 실행
    local test_command="xcodebuild test \
        -workspace $WORKSPACE_PATH \
        -scheme $scheme \
        -destination '$DESTINATION' \
        -enableCodeCoverage YES \
        -resultBundlePath ./TestResults/${module}Tests.xcresult \
        -quiet"
    
    log_test "실행 명령: $test_command"
    
    if eval $test_command; then
        log_success "$module 테스트 통과"
        return 0
    else
        log_error "$module 테스트 실패"
        return 1
    fi
}

# 테스트 결과 분석
analyze_test_results() {
    local module=$1
    local result_path="./TestResults/${module}Tests.xcresult"
    
    if [ -d "$result_path" ]; then
        log_info "$module 테스트 결과 분석 중..."
        
        # xcresulttool을 사용하여 테스트 결과 분석
        if command -v xcresulttool &> /dev/null; then
            local test_summary=$(xcresulttool get --format json --path "$result_path" | \
                jq -r '.actions[] | select(.actionResult.testsRef) | .actionResult.testsRef.id' 2>/dev/null || echo "")
            
            if [ ! -z "$test_summary" ]; then
                xcresulttool get --format json --path "$result_path" --id "$test_summary" | \
                    jq -r '.summaries.values[0].testStatus' 2>/dev/null || echo "결과 분석 실패"
            fi
        fi
    fi
}

# 코드 커버리지 보고서 생성
generate_coverage_report() {
    log_header "코드 커버리지 보고서 생성"
    
    for module in "${MODULES[@]}"; do
        local result_path="./TestResults/${module}Tests.xcresult"
        
        if [ -d "$result_path" ]; then
            log_info "$module 커버리지 보고서 생성 중..."
            
            # Xcode의 코드 커버리지 데이터 추출
            if command -v xcresulttool &> /dev/null; then
                xcresulttool get --format json --path "$result_path" > "./TestResults/${module}_coverage.json" 2>/dev/null || true
            fi
        fi
    done
    
    log_success "커버리지 보고서 생성 완료"
}

# 테스트 리포트 생성
generate_test_report() {
    log_header "테스트 리포트 생성"
    
    local report_file="./TestResults/test_report.md"
    local date_time=$(date "+%Y-%m-%d %H:%M:%S")
    
    cat > "$report_file" << EOF
# Kingthereum iOS 테스트 리포트

**생성 일시:** $date_time
**테스트 프레임워크:** Swift Testing (iOS 17+)
**Xcode 버전:** $(xcodebuild -version | head -n 1)

## 테스트 개요

### 테스트 대상 모듈
EOF

    for module in "${MODULES[@]}"; do
        echo "- $module" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

### 테스트 아키텍처
- **단위 테스트:** 각 모듈의 핵심 기능 테스트
- **Mock 객체:** 외부 의존성 격리를 위한 테스트 더블 사용
- **비동기 테스트:** async/await 패턴을 사용한 비동기 코드 테스트
- **에러 케이스:** 예외 상황 및 에러 핸들링 테스트
- **성능 테스트:** .timeLimit() trait을 사용한 성능 측정

## 모듈별 테스트 결과

EOF

    for module in "${MODULES[@]}"; do
        cat >> "$report_file" << EOF
### $module 모듈

#### 테스트 구성
EOF
        case $module in
            "Core")
                cat >> "$report_file" << EOF
- **ModelTests**: Wallet, Transaction, Token, Network 모델 테스트
- **FormatterTests**: 다양한 포맷터 유틸리티 테스트
- **통합 테스트**: 모델 간 상호작용 테스트
EOF
                ;;
            "SecurityKit")
                cat >> "$report_file" << EOF
- **BiometricAuthManagerTests**: Face ID, Touch ID 인증 테스트
- **KeychainManagerTests**: 키체인 저장/조회/삭제 테스트
- **통합 테스트**: 보안 워크플로우 전체 테스트
EOF
                ;;
            "WalletKit")
                cat >> "$report_file" << EOF
- **EthereumWorkerTests**: 이더리움 블록체인 상호작용 테스트
- **TokenWorkerTests**: ERC-20 토큰 관리 테스트
- **WalletServiceTests**: 지갑 서비스 통합 테스트
EOF
                ;;
        esac
        
        echo "" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Swift Testing 주요 기능 활용

### 1. 매개변수화 테스트 (@Test(arguments:))
- 다양한 입력값에 대한 체계적 테스트
- 테스트 코드 중복 제거 (50-60% 감소)
- 데이터 기반 테스트 케이스 구성

### 2. 테스트 Traits
- \`.timeLimit(.seconds(n))\`: 성능 테스트 시간 제한
- \`.serialized\`: 순차 실행이 필요한 테스트
- \`.tags()\`: 테스트 분류 및 선택적 실행

### 3. 향상된 어설션
- \`#expect()\`: 명확한 실패 메시지
- \`#require()\`: 조건부 테스트 실행
- 향상된 에러 정보 제공

### 4. 비동기 테스트 지원
- 네이티브 async/await 지원
- confirmation API로 향상된 비동기 테스트
- Task 취소 및 타임아웃 테스트

## 테스트 모범 사례

### 1. Given-When-Then 패턴
모든 테스트는 명확한 3단계 구조를 따릅니다:
- **Given**: 테스트 전제 조건 설정
- **When**: 테스트할 동작 실행
- **Then**: 결과 검증

### 2. Mock 객체 활용
- 외부 의존성 격리
- 예측 가능한 테스트 환경 구성
- 네트워크, 키체인, 생체인증 등 시스템 의존성 모킹

### 3. 포괄적 에러 테스트
- 정상 케이스와 에러 케이스 모두 테스트
- 다양한 실패 시나리오 검증
- 복구 로직 테스트

### 4. 성능 및 동시성 테스트
- 시간 제한을 통한 성능 검증
- 동시 실행 시나리오 테스트
- 메모리 및 리소스 누수 방지

## 지속적 개선

- **테스트 커버리지**: 핵심 비즈니스 로직 높은 커버리지 유지
- **테스트 속도**: 빠른 피드백을 위한 효율적 테스트 실행
- **테스트 안정성**: Flaky 테스트 최소화
- **유지보수성**: 읽기 쉽고 수정하기 쉬운 테스트 코드

EOF

    log_info "테스트 리포트 생성: $report_file"
    log_success "테스트 리포트 생성 완료"
}

# 정리
cleanup() {
    log_header "정리"
    
    # 시뮬레이터 종료 (옵션)
    # xcrun simctl shutdown all
    
    log_success "정리 완료"
}

# 메인 실행 함수
main() {
    log_header "Kingthereum iOS Swift Testing 실행"
    
    # 결과 디렉토리 생성
    mkdir -p TestResults
    
    # 전체 테스트 결과 추적
    local failed_modules=()
    local passed_modules=()
    
    # 전제 조건 확인
    check_prerequisites
    
    # 시뮬레이터 설정
    setup_simulator
    
    # 각 모듈별 테스트 실행
    for module in "${MODULES[@]}"; do
        echo ""
        if run_module_tests "$module"; then
            passed_modules+=("$module")
            analyze_test_results "$module"
        else
            failed_modules+=("$module")
        fi
    done
    
    # 결과 요약
    echo ""
    log_header "테스트 결과 요약"
    
    if [ ${#passed_modules[@]} -gt 0 ]; then
        log_success "통과한 모듈 (${#passed_modules[@]}개):"
        for module in "${passed_modules[@]}"; do
            echo -e "  ${GREEN}✓${NC} $module"
        done
    fi
    
    if [ ${#failed_modules[@]} -gt 0 ]; then
        log_error "실패한 모듈 (${#failed_modules[@]}개):"
        for module in "${failed_modules[@]}"; do
            echo -e "  ${RED}✗${NC} $module"
        done
    fi
    
    # 커버리지 및 리포트 생성
    generate_coverage_report
    generate_test_report
    
    # 정리
    cleanup
    
    # 최종 결과
    if [ ${#failed_modules[@]} -eq 0 ]; then
        log_success "모든 테스트가 성공적으로 완료되었습니다! 🎉"
        exit 0
    else
        log_error "일부 테스트가 실패했습니다. 로그를 확인해주세요."
        exit 1
    fi
}

# 스크립트 실행
main "$@"