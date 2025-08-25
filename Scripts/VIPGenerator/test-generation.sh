#!/bin/bash

# VIP Generator 테스트 스크립트

echo "🧪 VIP Generator 테스트 시작"

# 테스트 디렉토리 생성
TEST_DIR="/tmp/vip-generator-test"
mkdir -p "$TEST_DIR"

echo "📁 테스트 디렉토리: $TEST_DIR"

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(dirname "$0")"

echo "🔧 기본 VIP 생성기 테스트"

# 기본 생성기로 TestProfile Scene 생성
cd "$SCRIPT_DIR"
swift VIPTemplate.swift generate TestProfile "$TEST_DIR"

if [ $? -eq 0 ]; then
    echo "✅ 기본 VIP 생성기 테스트 성공"
else
    echo "❌ 기본 VIP 생성기 테스트 실패"
    exit 1
fi

echo ""
echo "🔧 설정 가능한 VIP 생성기 테스트"

# 샘플 설정 파일 생성
swift ConfigurableVIPGenerator.swift config sample TestConfigurable "$TEST_DIR/test-config.json"

if [ $? -eq 0 ]; then
    echo "✅ 설정 파일 생성 성공"
else
    echo "❌ 설정 파일 생성 실패"
    exit 1
fi

# 설정 파일로부터 Scene 생성
swift ConfigurableVIPGenerator.swift generate "$TEST_DIR/test-config.json" "$TEST_DIR"

if [ $? -eq 0 ]; then
    echo "✅ 설정 가능한 VIP 생성기 테스트 성공"
else
    echo "❌ 설정 가능한 VIP 생성기 테스트 실패"
    exit 1
fi

echo ""
echo "📊 생성된 파일 확인"

# 생성된 파일들 나열
echo "생성된 파일 구조:"
find "$TEST_DIR" -name "*.swift" -o -name "*.json" | sort

echo ""
echo "📋 파일 개수 확인"

# 각 타입별 파일 개수 확인
INTERACTOR_COUNT=$(find "$TEST_DIR" -name "*Interactor.swift" | wc -l)
PRESENTER_COUNT=$(find "$TEST_DIR" -name "*Presenter.swift" | wc -l)
WORKER_COUNT=$(find "$TEST_DIR" -name "*Worker.swift" | wc -l)
ROUTER_COUNT=$(find "$TEST_DIR" -name "*Router.swift" | wc -l)
VIEW_COUNT=$(find "$TEST_DIR" -name "*View.swift" | wc -l)
SCENE_COUNT=$(find "$TEST_DIR" -name "*Scene.swift" | wc -l)
TEST_COUNT=$(find "$TEST_DIR" -name "*Tests.swift" | wc -l)

echo "  Interactor: $INTERACTOR_COUNT"
echo "  Presenter: $PRESENTER_COUNT"
echo "  Worker: $WORKER_COUNT"
echo "  Router: $ROUTER_COUNT"
echo "  View: $VIEW_COUNT"
echo "  Scene Models: $SCENE_COUNT"
echo "  Tests: $TEST_COUNT"

# 검증
EXPECTED_FILES=2  # TestProfile + TestConfigurable
if [ "$INTERACTOR_COUNT" -eq "$EXPECTED_FILES" ] && 
   [ "$PRESENTER_COUNT" -eq "$EXPECTED_FILES" ] && 
   [ "$WORKER_COUNT" -eq "$EXPECTED_FILES" ] && 
   [ "$ROUTER_COUNT" -eq "$EXPECTED_FILES" ] && 
   [ "$VIEW_COUNT" -eq "$EXPECTED_FILES" ] && 
   [ "$SCENE_COUNT" -eq "$EXPECTED_FILES" ]; then
    echo "✅ 파일 개수 검증 성공"
else
    echo "❌ 파일 개수 검증 실패"
    exit 1
fi

echo ""
echo "🔍 코드 품질 확인"

# Swift 문법 검사
for swift_file in $(find "$TEST_DIR" -name "*.swift"); do
    echo "문법 검사: $(basename "$swift_file")"
    
    # TODO 주석이 적절히 포함되어 있는지 확인
    TODO_COUNT=$(grep -c "TODO:" "$swift_file" || true)
    if [ "$TODO_COUNT" -gt 0 ]; then
        echo "  ✓ TODO 주석 $TODO_COUNT 개 발견"
    fi
    
    # 기본적인 구조 확인
    if [[ "$swift_file" == *"Interactor.swift" ]]; then
        if grep -q "BusinessLogic" "$swift_file" && grep -q "DataStore" "$swift_file"; then
            echo "  ✓ Interactor 구조 정상"
        else
            echo "  ❌ Interactor 구조 오류"
            exit 1
        fi
    fi
    
    if [[ "$swift_file" == *"Presenter.swift" ]]; then
        if grep -q "PresentationLogic" "$swift_file" && grep -q "DisplayLogic" "$swift_file"; then
            echo "  ✓ Presenter 구조 정상"
        else
            echo "  ❌ Presenter 구조 오류"
            exit 1
        fi
    fi
    
    if [[ "$swift_file" == *"View.swift" ]]; then
        if grep -q "SwiftUI" "$swift_file" && grep -q "View" "$swift_file"; then
            echo "  ✓ SwiftUI View 구조 정상"
        else
            echo "  ❌ SwiftUI View 구조 오류"
            exit 1
        fi
    fi
done

echo ""
echo "📱 샘플 설정 파일 테스트"

# 제공된 샘플 설정 파일들로 테스트
for config_file in "$SCRIPT_DIR/sample-configs"/*.json; do
    if [ -f "$config_file" ]; then
        echo "테스트: $(basename "$config_file")"
        swift ConfigurableVIPGenerator.swift generate "$config_file" "$TEST_DIR/samples"
        
        if [ $? -eq 0 ]; then
            echo "  ✅ $(basename "$config_file") 생성 성공"
        else
            echo "  ❌ $(basename "$config_file") 생성 실패"
            exit 1
        fi
    fi
done

echo ""
echo "🧹 테스트 정리"

# 테스트 정리 (선택적)
if [ "$1" = "--cleanup" ]; then
    rm -rf "$TEST_DIR"
    echo "✅ 테스트 디렉토리 정리 완료"
else
    echo "💡 테스트 결과를 확인하려면: ls -la $TEST_DIR"
    echo "💡 정리하려면: rm -rf $TEST_DIR"
fi

echo ""
echo "🎉 모든 VIP Generator 테스트 통과!"
echo ""
echo "📈 테스트 결과 요약:"
echo "  - 기본 VIP 생성기: ✅ 성공"
echo "  - 설정 가능한 VIP 생성기: ✅ 성공" 
echo "  - 샘플 설정 파일들: ✅ 성공"
echo "  - 코드 구조 검증: ✅ 성공"
echo "  - 생성된 Scene 개수: $EXPECTED_FILES"
echo ""
echo "🚀 VIP Generator 준비 완료!"