import SwiftUI
import DesignSystem
import Core

/// 니모닉 관련 뷰 모드
enum MnemonicMode {
    case display  // 새로 생성된 니모닉 표시
    case input    // 기존 니모닉 입력
}

/// 니모닉 생성 및 복원을 위한 뷰
struct MnemonicView: View {
    let mode: MnemonicMode
    let mnemonic: String?
    let onMnemonicSubmitted: (String) -> Void
    let onBackupConfirmed: () -> Void
    
    @State private var inputMnemonic = ""
    @State private var mnemonicWords: [String] = Array(repeating: "", count: 12)
    @State private var showCopyAlert = false
    @State private var isValid = false
    @FocusState private var focusedField: Int?
    @State private var pastedMnemonic = ""
    
    // Task 생명주기 관리
    @State private var clipboardTask: Task<Void, Never>?
    @State private var focusTask: Task<Void, Never>?
    @State private var messageTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if mode == .display {
                        displayMnemonicSection
                        warningSection
                        copyButtonSection
                        confirmButtonSection
                    } else {
                        inputMnemonicSection
                        submitButtonSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(LinearGradient.enhancedBackgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(mode == .display ? "지갑 백업" : "지갑 복원")
        }
        .onAppear {
            if mode == .display, let mnemonic = mnemonic {
                mnemonicWords = mnemonic.components(separatedBy: " ")
            } else if mode == .input {
                // 입력 모드에서는 첫 번째 필드에 포커스
                focusTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                        if !Task.isCancelled {
                            focusedField = 0
                        }
                    } catch is CancellationError {
                        // 정상적인 취소 - 아무것도 하지 않음
                        return
                    } catch {
                        print("Focus task unexpected error: \(error)")
                    }
                }
            }
        }
        .onDisappear {
            // 모든 Task 취소
            clipboardTask?.cancel()
            focusTask?.cancel()
            messageTask?.cancel()
        }
        .toolbar {
            if mode == .input {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: 12) {
                        Button {
                            moveToPreviousField()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.caption)
                                Text("이전")
                                    .font(.subheadline)
                            }
                            .foregroundColor(focusedField == nil || focusedField == 0 ? .secondary : .kingBlue)
                        }
                        .disabled(focusedField == nil || focusedField == 0)
                        
                        Button {
                            moveToNextFieldFromToolbar()
                        } label: {
                            HStack(spacing: 4) {
                                Text("다음")
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(focusedField == nil || focusedField == 11 ? .secondary : .kingBlue)
                        }
                        .disabled(focusedField == nil || focusedField == 11)
                        
                        Spacer()
                        
                        Button {
                            focusedField = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.caption)
                                Text("완료")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(LinearGradient.primaryGradient)
                        }
                    }
                }
            }
        }
        .alert("클립보드 복사", isPresented: $showCopyAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("니모닉 문구가 복사되었습니다\n30초 후 자동 삭제됩니다")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Glass Icon Container
            ZStack {
                Circle()
                    .fill(.ultraThickMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.glassBorderPrimary, lineWidth: 2)
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .glassShadowMedium, radius: 12, x: 0, y: 6)
                
                Image(systemName: mode == .display ? "shield.lefthalf.filled" : "key.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            
            VStack(spacing: 8) {
                Text(mode == .display ? "지갑 백업" : "지갑 복원")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 6) {
                    Image(systemName: mode == .display ? "doc.text.fill" : "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(LinearGradient.primaryGradient)
                    Text(mode == .display ? "12개 단어 보관" : "12개 단어 입력")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Display Mnemonic Section
    private var displayMnemonicSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title3)
                    .foregroundColor(.kingBlue)
                Text("복구 문구")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(mnemonicWords.enumerated()), id: \.offset) { index, word in
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 24, height: 24)
                            Text("\(index + 1)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.kingBlue)
                        }
                        
                        Text(word)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassCard(style: .subtle)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Warning Section
    private var warningSection: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.systemOrange.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(Color.systemOrange)
                }
                Text("보안 경고")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.systemOrange)
                Spacer()
            }
            
            VStack(spacing: 12) {
                warningIconItem(icon: "eye.slash.fill", text: "분실 시 영구 접근 불가")
                warningIconItem(icon: "person.2.slash.fill", text: "타인과 공유 금지")
                warningIconItem(icon: "camera.fill", text: "스크린샷 저장 금지")
                warningIconItem(icon: "pencil.and.outline", text: "오프라인 보관 권장")
            }
        }
        .padding(20)
        .glassCard(style: .prominent)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(Color.systemOrange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func warningIconItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.systemOrange)
                .frame(width: 20)
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Copy Button Section
    private var copyButtonSection: some View {
        GlassButton(
            icon: "doc.on.doc.fill",
            title: "클립보드 복사",
            style: .wallet
        ) {
            if let mnemonic = mnemonic {
                UIPasteboard.general.string = mnemonic
                showCopyAlert = true
                
                // 30초 후 클립보드 자동 삭제
                clipboardTask?.cancel()
                clipboardTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .seconds(30))
                        if !Task.isCancelled && UIPasteboard.general.string == mnemonic {
                            UIPasteboard.general.string = ""
                        }
                    } catch is CancellationError {
                        // 정상적인 취소 - 클립보드는 그대로 유지
                        return
                    } catch {
                        print("Clipboard cleanup unexpected error: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Confirm Button Section
    private var confirmButtonSection: some View {
        GlassButton(
            icon: "checkmark.shield.fill",
            title: "백업 완료",
            style: .success
        ) {
            onBackupConfirmed()
        }
    }
    
    // MARK: - Input Mnemonic Section
    private var inputMnemonicSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title3)
                    .foregroundColor(.kingBlue)
                
                Text("복구 문구")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if mnemonicWords.contains(where: { !$0.isEmpty }) {
                    GlassButton(
                        icon: "trash",
                        style: .icon
                    ) {
                        clearAllFields()
                    }
                }
                
                GlassButton(
                    icon: "doc.on.clipboard",
                    style: .icon
                ) {
                    pasteFromClipboard()
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(0..<12, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        GlassTextField(
                            text: $mnemonicWords[index],
                            placeholder: "단어 입력",
                            style: .default,
                            keyboardType: .asciiCapable,
                            submitLabel: index == 11 ? .done : .next,
                            onEditingChanged: { editing in
                                if editing {
                                    focusedField = index
                                }
                            },
                            onSubmit: {
                                moveToNextField(from: index)
                            }
                        )
                        .focused($focusedField, equals: index)
                        .onChange(of: mnemonicWords[index]) { oldValue, newValue in
                            // 자동으로 다음 필드로 이동
                            if !oldValue.isEmpty && newValue.isEmpty {
                                // 백스페이스로 삭제한 경우는 이전 필드로 이동
                                if index > 0 {
                                    Task { @MainActor in
                                        focusedField = index - 1
                                    }
                                }
                                return
                            }
                            
                            // 스페이스가 입력되면 다음 필드로 이동
                            if newValue.contains(" ") {
                                let cleanWord = newValue.replacingOccurrences(of: " ", with: "")
                                mnemonicWords[index] = cleanWord
                                // 스페이스바 입력시 즉시 이동
                                if index < 11 {
                                    focusedField = index + 1
                                }
                            }
                            
                            // 탭이나 개행 문자 제거
                            if newValue.contains("\t") || newValue.contains("\n") {
                                let cleanWord = newValue.replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: "\n", with: "")
                                mnemonicWords[index] = cleanWord
                            }
                            
                            updateValidation(words: mnemonicWords)
                        }
                    }
                }
            }
            
            // 진행 상황 표시
            let filledCount = mnemonicWords.filter { !$0.isEmpty }.count
            if filledCount > 0 {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill((filledCount == 12 ? Color.systemGreen : Color.systemOrange).opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: filledCount == 12 ? "checkmark.circle.fill" : "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(filledCount == 12 ? Color.systemGreen : Color.systemOrange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(filledCount)/12")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("단어 입력됨")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 진행률 바
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int((Double(filledCount) / 12.0) * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(filledCount == 12 ? Color.systemGreen : Color.systemOrange)
                        ProgressView(value: Double(filledCount), total: 12)
                            .frame(width: 60)
                            .tint(filledCount == 12 ? Color.systemGreen : Color.systemOrange)
                    }
                }
                .padding(12)
                .glassCard(style: .subtle)
            }
            
            if !pastedMnemonic.isEmpty {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.systemGreen.opacity(0.15))
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.systemGreen)
                    }
                    Text(pastedMnemonic.contains("12개") ? pastedMnemonic : "자동 입력 완료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(style: .subtle)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Submit Button Section
    private var submitButtonSection: some View {
        GlassButton(
            icon: "arrow.clockwise.circle.fill",
            title: "지갑 복원",
            style: isValid ? .wallet : .secondary,
            isEnabled: isValid
        ) {
            let mnemonic = mnemonicWords.joined(separator: " ")
            onMnemonicSubmitted(mnemonic)
        }
    }
    
    // MARK: - Helper Methods
    private func updateValidation(words: [String]) {
        let trimmedWords = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        isValid = trimmedWords.allSatisfy { !$0.isEmpty } && trimmedWords.count == 12
    }
    
    private func moveToNextField(from currentIndex: Int) {
        // 부드러운 포커스 전환을 위해 약간의 지연 추가
        Task { @MainActor in
            if currentIndex < 11 {
                focusedField = currentIndex + 1
            } else {
                // 마지막 필드에서 완료
                focusedField = nil
                if isValid {
                    let mnemonic = mnemonicWords.joined(separator: " ")
                    onMnemonicSubmitted(mnemonic)
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            let words = clipboardContent
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            if words.count == 12 {
                // 12개 단어가 있으면 자동으로 입력
                for (index, word) in words.enumerated() {
                    if index < 12 {
                        mnemonicWords[index] = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                    }
                }
                pastedMnemonic = words.joined(separator: " ")
                updateValidation(words: mnemonicWords)
                focusedField = nil // 포커스 해제
                
                // 3초 후 메시지 숨기기
                messageTask?.cancel()
                messageTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .seconds(3))
                        if !Task.isCancelled {
                            pastedMnemonic = ""
                        }
                    } catch is CancellationError {
                        // 정상적인 취소 - 메시지는 그대로 유지
                        return
                    } catch {
                        print("Message cleanup unexpected error: \(error)")
                    }
                }
            } else if words.count > 12 {
                // 12개 이상이면 처음 12개만 사용
                for index in 0..<12 {
                    mnemonicWords[index] = words[index].lowercased().trimmingCharacters(in: .punctuationCharacters)
                }
                pastedMnemonic = "처음 12개 단어만 입력되었습니다"
                updateValidation(words: mnemonicWords)
                focusedField = nil
                
                messageTask?.cancel()
                messageTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .seconds(3))
                        if !Task.isCancelled {
                            pastedMnemonic = ""
                        }
                    } catch is CancellationError {
                        // 정상적인 취소 - 메시지는 그대로 유지
                        return
                    } catch {
                        print("Message cleanup unexpected error: \(error)")
                    }
                }
            } else {
                // 12개보다 적으면 현재 포커스된 필드부터 순서대로 입력
                let startIndex = focusedField ?? 0
                for (wordIndex, word) in words.enumerated() {
                    let fieldIndex = startIndex + wordIndex
                    if fieldIndex < 12 {
                        mnemonicWords[fieldIndex] = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                    }
                }
                // 다음 빈 필드로 포커스 이동
                let nextEmptyIndex = mnemonicWords.firstIndex(where: { $0.isEmpty })
                focusedField = nextEmptyIndex
                updateValidation(words: mnemonicWords)
            }
        }
    }
    
    private func clearAllFields() {
        mnemonicWords = Array(repeating: "", count: 12)
        focusedField = 0
        pastedMnemonic = ""
        updateValidation(words: mnemonicWords)
    }
    
    private func moveToPreviousField() {
        Task { @MainActor in
            if let current = focusedField, current > 0 {
                focusedField = current - 1
            }
        }
    }
    
    private func moveToNextFieldFromToolbar() {
        Task { @MainActor in
            if let current = focusedField, current < 11 {
                focusedField = current + 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MnemonicView(
        mode: .display,
        mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        onMnemonicSubmitted: { _ in },
        onBackupConfirmed: { }
    )
}

#Preview {
    MnemonicView(
        mode: .input,
        mnemonic: nil,
        onMnemonicSubmitted: { _ in },
        onBackupConfirmed: { }
    )
}
