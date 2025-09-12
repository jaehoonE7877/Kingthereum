import SwiftUI

import DesignSystem
import Entity
import web3swift
import Web3Core

struct MnemonicImportView: View {
    let viewStore: AuthenticationViewStore
    
    @State private var mnemonicWords: [String] = Array(repeating: "", count: 12)
    @State private var currentWordIndex = 0
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showMnemonicPaste = false
    @FocusState private var focusedIndex: Int?
    
    private let standardWordCount = 12
    private let wordValidator = MnemonicValidator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: KingDesignTokens.Spacing.xl) {
                // Header Section - Minimal
                VStack(spacing: KingDesignTokens.Spacing.lg) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(KingDesignTokens.Colors.accent)
                    
                    VStack(spacing: KingDesignTokens.Spacing.sm) {
                        Text("Import Wallet")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(KingDesignTokens.Colors.primaryText)
                        
                        Text("Enter your 12-word recovery phrase")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, KingDesignTokens.Spacing.xl)
                
                // Mnemonic Input Grid
                VStack(spacing: KingDesignTokens.Spacing.lg) {
                    // Quick Paste Section - Minimal
                    VStack(spacing: KingDesignTokens.Spacing.md) {
                        Button {
                            showMnemonicPaste.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Paste from clipboard")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(KingDesignTokens.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(KingDesignTokens.Colors.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(KingDesignTokens.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        if showMnemonicPaste {
                            PasteableTextField(
                                onPaste: handleMnemonicPaste,
                                onCancel: { showMnemonicPaste = false }
                            )
                        }
                    }
                    
                    // Word Input Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: KingDesignTokens.Spacing.sm), count: 2), spacing: KingDesignTokens.Spacing.sm) {
                        ForEach(0..<standardWordCount, id: \.self) { index in
                            MnemonicWordField(
                                index: index,
                                word: $mnemonicWords[index],
                                isValid: wordValidator.isValidWord(mnemonicWords[index]),
                                isFocused: focusedIndex == index,
                                onCommit: {
                                    moveToNextField()
                                }
                            )
                            .focused($focusedIndex, equals: index)
                            .onTapGesture {
                                focusedIndex = index
                            }
                        }
                    }
                }
                
                // Validation Error
                if let error = validationError {
                    HStack(spacing: KingDesignTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.error)
                        
                        Text(error)
                            .font(KingDesignTokens.Typography.caption)
                            .foregroundColor(KingDesignTokens.Colors.error)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(KingDesignTokens.Colors.error.opacity(0.1))
                    .cornerRadius(KingDesignTokens.Radius.md)
                }
                
                // Progress Indicator - Minimal
                VStack(spacing: KingDesignTokens.Spacing.sm) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                        Spacer()
                        Text("\(filledWordsCount)/12")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(KingDesignTokens.Colors.accent)
                    }
                    
                    ProgressView(value: Double(filledWordsCount), total: Double(standardWordCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: KingDesignTokens.Colors.accent))
                        .frame(height: 2)
                }
                
                // Action Buttons - Professional
                VStack(spacing: KingDesignTokens.Spacing.md) {
                    Button {
                        validateAndImportWallet()
                    } label: {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isValidating ? "Importing..." : "Import Wallet")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(KingDesignTokens.Colors.systemWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isImportEnabled ? KingDesignTokens.Colors.accent : KingDesignTokens.Colors.border)
                        .cornerRadius(12)
                    }
                    .disabled(!isImportEnabled || isValidating)
                    
                    Button {
                        clearAllWords()
                    } label: {
                        Text("Clear all")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(KingDesignTokens.Colors.secondaryText)
                    }
                }
                
                // Security Notice
                SecurityNoticeCard()
            }
            .padding(.horizontal, KingDesignTokens.Spacing.lg)
        }
        .onAppear {
            focusedIndex = 0
        }
        .onChange(of: mnemonicWords) { _, _ in
            validationError = nil
        }
    }
    
    // MARK: - Computed Properties
    
    private var filledWordsCount: Int {
        mnemonicWords.filter { !$0.isEmpty }.count
    }
    
    private var isImportEnabled: Bool {
        filledWordsCount == standardWordCount && !isValidating
    }
    
    // MARK: - Actions
    
    private func moveToNextField() {
        if focusedIndex != nil && focusedIndex! < standardWordCount - 1 {
            focusedIndex! += 1
        }
    }
    
    private func handleMnemonicPaste(_ text: String) {
        // 스마트 파싱: 다양한 구분자 지원 (공백, 탭, 줄바꿈, 쉼표 등)
        let cleanedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[,;\\t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        let words = cleanedText.components(separatedBy: " ").filter { !$0.isEmpty }
        let validWordCounts: Set<Int> = [12, 15, 18, 21, 24]
        
        if validWordCounts.contains(words.count) {
            // 적절한 단어 개수인 경우
            if words.count == 12 {
                // 12개 단어면 기존 필드에 채우기
                mnemonicWords = words
                showMnemonicPaste = false
                focusedIndex = nil
            } else {
                // 12개 이외의 경우 사용자에게 알림
                let validationResult = wordValidator.validateMnemonicDetailed(cleanedText)
                if validationResult.isValid {
                    // 유효하지만 12개가 아닌 경우 - 지원하지 않음을 안내
                    validationError = "현재 \(words.count)개 단어 지갑을 지원합니다만, 이 앱은 12개 단어 지갑만 지원합니다."
                } else {
                    // 유효하지 않은 경우 상세한 에러 표시
                    validationError = validationResult.errorType?.localizedDescription ?? "유효하지 않은 복구 구문입니다."
                }
            }
        } else {
            // 지원하지 않는 단어 개수
            validationError = "\(words.count)개 단어가 입력되었습니다. 지원되는 단어 개수: \(validWordCounts.sorted().map(String.init).joined(separator: ", "))개"
        }
    }
    
    private func validateAndImportWallet() {
        isValidating = true
        validationError = nil
        
        // 1. 기본 검증 - 모든 단어 입력 확인
        guard filledWordsCount == standardWordCount else {
            validationError = "모든 단어를 입력해주세요."
            isValidating = false
            return
        }
        
        // 2. 프로덕션 급 상세 검증 수행
        let mnemonicString = mnemonicWords.joined(separator: " ")
        let validationResult = wordValidator.validateMnemonicDetailed(mnemonicString)
        
        if !validationResult.isValid {
            // 상세한 에러 메시지 생성
            if let errorType = validationResult.errorType {
                validationError = errorType.localizedDescription
                
                // 단어 제안이 있는 경우 추가 정보 표시
                if !validationResult.suggestions.isEmpty {
                    let suggestionsText = validationResult.suggestions
                        .map { word, suggestions in
                            "'\(word)' → \(suggestions.joined(separator: ", "))"
                        }
                        .joined(separator: "\n")
                    validationError! += "\n\n💡 추천 단어:\n\(suggestionsText)"
                }
            } else {
                validationError = "알 수 없는 검증 오류가 발생했습니다."
            }
            isValidating = false
            return
        }
        
        // 3. 모든 검증 통과 - 지갑 복구 실행
        let request = AuthenticationScene.ImportWallet.Request(
            walletName: "복구된 지갑",
            mnemonic: mnemonicString,
            pin: "" // PIN은 다음 단계에서 설정
        )
        
        viewStore.interactor?.importWalletFromMnemonic(request: request)
        isValidating = false
    }
    
    private func clearAllWords() {
        mnemonicWords = Array(repeating: "", count: 12)
        focusedIndex = 0
        validationError = nil
    }
}

// MARK: - Supporting Views

/// 니모닉 단어 입력 필드
struct MnemonicWordField: View {
    let index: Int
    @Binding var word: String
    let isValid: Bool
    let isFocused: Bool
    let onCommit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
            Text("\(index + 1)")
                .font(KingDesignTokens.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(KingDesignTokens.Colors.tertiaryText)
            
            TextField("단어 입력", text: $word, onCommit: onCommit)
                .font(KingDesignTokens.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, KingDesignTokens.Spacing.md)
                .padding(.vertical, KingDesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                        .fill(KingDesignTokens.Colors.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                                .stroke(
                                    word.isEmpty ? KingDesignTokens.Colors.border :
                                    isValid ? KingDesignTokens.Colors.success :
                                    KingDesignTokens.Colors.error,
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .foregroundColor(KingDesignTokens.Colors.primaryText)
        }
    }
}

/// 클립보드 붙여넣기 필드
struct PasteableTextField: View {
    let onPaste: (String) -> Void
    let onCancel: () -> Void
    
    @State private var pasteText = ""
    
    var body: some View {
        VStack(spacing: KingDesignTokens.Spacing.sm) {
            TextField("복구 구문을 붙여넣으세요 (12개 단어)", text: $pasteText, axis: .vertical)
                .font(KingDesignTokens.Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(3...6)
                .padding()
                .background(KingDesignTokens.Colors.surfaceSecondary)
                .cornerRadius(KingDesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: KingDesignTokens.Radius.md)
                        .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
                )
            
            HStack(spacing: KingDesignTokens.Spacing.md) {
                Button("취소") {
                    onCancel()
                }
                .font(KingDesignTokens.Typography.body)
                .foregroundColor(KingDesignTokens.Colors.secondaryText)
                
                Spacer()
                
                Button("붙여넣기") {
                    onPaste(pasteText)
                }
                .font(KingDesignTokens.Typography.body)
                .fontWeight(.semibold)
                .foregroundColor(KingDesignTokens.Colors.accent)
                .disabled(pasteText.isEmpty)
            }
        }
        .padding()
        .background(KingDesignTokens.Colors.background)
        .cornerRadius(KingDesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg)
                .stroke(KingDesignTokens.Colors.border, lineWidth: 1)
        )
    }
}

/// 보안 안내 카드
struct SecurityNoticeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.md) {
            HStack(spacing: KingDesignTokens.Spacing.sm) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(KingDesignTokens.Typography.body)
                    .foregroundColor(KingDesignTokens.Colors.warning)
                
                Text("보안 주의사항")
                    .font(KingDesignTokens.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(KingDesignTokens.Colors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: KingDesignTokens.Spacing.xs) {
                SecurityGuideItem(text: "복구 구문은 대소문자를 구분하지 않습니다")
                SecurityGuideItem(text: "단어 사이에는 공백 하나만 사용하세요")
                SecurityGuideItem(text: "올바른 순서로 입력해야 합니다")
                SecurityGuideItem(text: "복구가 완료되면 기존 데이터는 삭제됩니다")
            }
        }
        .padding()
        .background(KingDesignTokens.Colors.warning.opacity(0.05))
        .cornerRadius(KingDesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: KingDesignTokens.Radius.lg)
                .stroke(KingDesignTokens.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Mnemonic Validator

/// 프로덕션 급 BIP39 니모닉 검증 클래스
class MnemonicValidator {
    
    /// 단어가 BIP39 표준 단어 목록에 있는지 확인
    /// - Parameter word: 검증할 단어
    /// - Returns: 유효한 BIP39 단어인지 여부
    func isValidWord(_ word: String) -> Bool {
        let normalizedWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedWord.isEmpty else { return false }
        
        // BIP39 체크섬 검증을 통한 단어 유효성 확인 (더 확실한 방법)
        // 임시로 12개 다른 단어들과 조합해서 검증
        let testWords = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon"]
        let testMnemonic = (testWords + [normalizedWord]).prefix(12).joined(separator: " ")
        
        // web3swift BIP39 검증 시도
        // web3swift에서 BIP39.mnemonicsToEntropy는 throwing이 아닐 수 있으므로 간단한 검증 사용
        let entropy = BIP39.mnemonicsToEntropy(testMnemonic)
        if entropy != nil && !entropy!.isEmpty {
            return true
        } else {
            // 단일 단어 검증 실패시 fallback 사용
            return isWordInBIP39List(normalizedWord)
        }
    }
    
    /// 니모닉 문구 전체의 유효성 검증 (체크섬 포함)
    /// - Parameter mnemonic: 검증할 니모닉 문구
    /// - Returns: 유효한 BIP39 니모닉인지 여부
    func isValidMnemonic(_ mnemonic: String) -> Bool {
        let cleanedMnemonic = mnemonic
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard !cleanedMnemonic.isEmpty else { return false }
        
        // 1. 단어 개수 검증 (12, 15, 18, 21, 24 개만 유효)
        let words = cleanedMnemonic.components(separatedBy: " ").filter { !$0.isEmpty }
        let validWordCounts: Set<Int> = [12, 15, 18, 21, 24]
        guard validWordCounts.contains(words.count) else { return false }
        
        // 2. 각 단어가 BIP39 목록에 있는지 확인
        guard words.allSatisfy({ isValidWord($0) }) else { return false }
        
        // 3. 실제 BIP39 체크섬 검증 (web3swift 사용)
        // BIP39 엔트로피 변환으로 체크섬 검증
        let entropy = BIP39.mnemonicsToEntropy(cleanedMnemonic, language: .english)
        return entropy != nil && !entropy!.isEmpty
    }
    
    /// 니모닉 문구의 상세 검증 결과 반환
    /// - Parameter mnemonic: 검증할 니모닉 문구
    /// - Returns: 검증 결과 상세 정보
    func validateMnemonicDetailed(_ mnemonic: String) -> MnemonicValidationResult {
        let cleanedMnemonic = mnemonic
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard !cleanedMnemonic.isEmpty else {
            return MnemonicValidationResult(
                isValid: false,
                errorType: .emptyInput,
                invalidWords: [],
                suggestions: [:]
            )
        }
        
        let words = cleanedMnemonic.components(separatedBy: " ").filter { !$0.isEmpty }
        let validWordCounts: Set<Int> = [12, 15, 18, 21, 24]
        
        // 단어 개수 검증
        guard validWordCounts.contains(words.count) else {
            return MnemonicValidationResult(
                isValid: false,
                errorType: .invalidWordCount(actual: words.count, expected: Array(validWordCounts)),
                invalidWords: [],
                suggestions: [:]
            )
        }
        
        // 개별 단어 검증 및 제안
        var invalidWords: [(index: Int, word: String)] = []
        var suggestions: [String: [String]] = [:]
        
        for (index, word) in words.enumerated() {
            if !isValidWord(word) {
                invalidWords.append((index: index + 1, word: word))
                suggestions[word] = generateWordSuggestions(for: word)
            }
        }
        
        if !invalidWords.isEmpty {
            return MnemonicValidationResult(
                isValid: false,
                errorType: .invalidWords(invalidWords),
                invalidWords: invalidWords,
                suggestions: suggestions
            )
        }
        
        // 체크섬 검증
        let entropy = BIP39.mnemonicsToEntropy(cleanedMnemonic, language: .english)
        if entropy != nil && !entropy!.isEmpty {
            return MnemonicValidationResult(
                isValid: true,
                errorType: nil,
                invalidWords: [],
                suggestions: [:]
            )
        } else {
            return MnemonicValidationResult(
                isValid: false,
                errorType: .invalidChecksum,
                invalidWords: [],
                suggestions: [:]
            )
        }
    }
    
    /// 유사한 BIP39 단어 제안 생성
    private func generateWordSuggestions(for word: String, maxSuggestions: Int = 3) -> [String] {
        // 일반적인 BIP39 단어 목록 사용 (fallback wordlist가 더 포괄적이므로)
        let commonWords = getAllBIP39Words()
        
        let normalizedInput = word.lowercased()
        var suggestions: [(word: String, score: Int)] = []
        
        for bip39Word in commonWords {
            let score = calculateSimilarity(normalizedInput, bip39Word)
            if score > 50 { // 최소 유사도 기준
                suggestions.append((word: bip39Word, score: score))
            }
        }
        
        return suggestions
            .sorted { $0.score > $1.score }
            .prefix(maxSuggestions)
            .map { $0.word }
    }
    
    /// 문자열 유사도 계산 (레벤슈타인 거리 기반)
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Int {
        let len1 = str1.count
        let len2 = str2.count
        
        // 길이 차이가 너무 크면 유사도 낮음
        if abs(len1 - len2) > 2 { return 0 }
        
        // 접두사 매칭 보너스
        if str2.hasPrefix(str1) { return 100 + len1 }
        if str1.hasPrefix(str2) { return 90 + len2 }
        
        // 간단한 문자 매칭 점수
        let commonChars = Set(str1).intersection(Set(str2)).count
        let maxLen = max(len1, len2)
        
        return maxLen > 0 ? (commonChars * 100) / maxLen : 0
    }
    
    /// 완전한 BIP39 단어 목록 반환
    private func getAllBIP39Words() -> [String] {
        // web3swift의 BIP39Language를 사용하여 완전한 2048개 영어 단어 목록 반환
        return BIP39Language.english.words
    }
    
    /// Fallback BIP39 단어 검증 (네트워크 오류 시)
    private func isWordInBIP39List(_ word: String) -> Bool {
        return getAllBIP39Words().contains(word.lowercased())
    }
}

// MARK: - Validation Result Models

/// 니모닉 검증 결과 상세 정보
struct MnemonicValidationResult {
    let isValid: Bool
    let errorType: MnemonicValidationError?
    let invalidWords: [(index: Int, word: String)]
    let suggestions: [String: [String]]
}

/// 니모닉 검증 오류 타입
enum MnemonicValidationError {
    case emptyInput
    case invalidWordCount(actual: Int, expected: [Int])
    case invalidWords([(index: Int, word: String)])
    case invalidChecksum
    
    var localizedDescription: String {
        switch self {
        case .emptyInput:
            return "복구 구문을 입력해주세요."
        case .invalidWordCount(let actual, let expected):
            return "\(actual)개 단어가 입력되었습니다. 유효한 단어 개수: \(expected.map(String.init).joined(separator: ", "))개"
        case .invalidWords(let words):
            let wordList = words.map { "\($0.index)번째: '\($0.word)'" }.joined(separator: ", ")
            return "유효하지 않은 단어: \(wordList)"
        case .invalidChecksum:
            return "복구 구문의 체크섬이 올바르지 않습니다. 단어 순서나 철자를 확인해주세요."
        }
    }
}
