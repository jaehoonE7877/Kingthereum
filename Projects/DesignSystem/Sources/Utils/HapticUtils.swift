import AVFoundation
import SwiftUI
import UIKit

/// 햅틱 피드백 및 사운드 유틸리티
/// 사용자 상호작용에 대한 촉각 및 청각 피드백 제공
@MainActor
public enum HapticUtils {
    
    // MARK: - Impact Feedback
    
    /// 가벼운 임팩트 피드백 (버튼 탭, 스위치 등)
    public static func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// 중간 임팩트 피드백 (일반적인 선택, 확인 등)
    public static func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// 강한 임팩트 피드백 (중요한 액션, 경고 등)
    public static func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// 부드러운 임팩트 피드백 (미묘한 반응, 부드러운 상호작용)
    public static func softImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// 단단한 임팩트 피드백 (강력한 선택, 확실한 반응)
    public static func rigidImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// 선택 변경 피드백 (picker, segmented control 등)
    public static func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// 성공 피드백
    public static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// 경고 피드백
    public static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// 에러 피드백
    public static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Custom Patterns
    
    /// 거래 완료 피드백 (성공 + 중간 임팩트)
    public static func transactionCompleted() {
        success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mediumImpact()
        }
    }
    
    /// 지갑 연결 피드백
    public static func walletConnected() {
        lightImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            success()
        }
    }
    
    /// 네트워크 오류 피드백
    public static func networkError() {
        error()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightImpact()
        }
    }
    
    /// PIN 입력 피드백
    public static func pinDigitEntered() {
        lightImpact()
    }
    
    /// PIN 완료 피드백
    public static func pinCompleted() {
        mediumImpact()
    }
    
    /// PIN 오류 피드백
    public static func pinError() {
        error()
        
        // 진동 패턴으로 오류 표현
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            lightImpact()
        }
    }
    
    /// QR 코드 스캔 성공 피드백
    public static func qrScanSuccess() {
        success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            mediumImpact()
        }
    }
    
    // MARK: - Sound Effects
    
    /// 시스템 사운드 재생
    public static func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    /// 성공 사운드
    public static func playSuccessSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1016)) // Tink
    }
    
    /// 에러 사운드
    public static func playErrorSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1006)) // Error
    }
    
    /// 알림 사운드
    public static func playNotificationSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1315)) // BeginRecording
    }
    
    // MARK: - Combination Effects
    
    /// 완전한 성공 피드백 (햅틱 + 사운드)
    public static func completeSuccess() {
        success()
        playSuccessSound()
    }
    
    /// 완전한 에러 피드백 (햅틱 + 사운드)
    public static func completeError() {
        error()
        playErrorSound()
    }
    
    // MARK: - Conditional Feedback
    
    /// 설정에 따른 조건부 피드백
    public static func conditionalFeedback(
        type: FeedbackType,
        respectsSettings: Bool = true
    ) {
        // 사용자 설정 확인 (실제 구현에서는 UserDefaults 또는 Settings에서 확인)
        if respectsSettings {
            let isHapticEnabled = UserDefaults.standard.bool(forKey: "haptic_feedback_enabled")
            let isSoundEnabled = UserDefaults.standard.bool(forKey: "sound_effects_enabled")
            
            if !isHapticEnabled && !isSoundEnabled {
                return
            }
            
            switch type {
            case .success:
                if isHapticEnabled { success() }
                if isSoundEnabled { playSuccessSound() }
            case .error:
                if isHapticEnabled { error() }
                if isSoundEnabled { playErrorSound() }
            case .impact(let style):
                if isHapticEnabled {
                    switch style {
                    case .light: lightImpact()
                    case .medium: mediumImpact()
                    case .heavy: heavyImpact()
                    case .soft:
                        softImpact()
                    case .rigid:
                        rigidImpact()
                    @unknown default:
                        mediumImpact() // 향후 추가될 수 있는 케이스에 대한 기본 처리
                    }
                }
            case .selection:
                if isHapticEnabled { selectionChanged() }
            }
        } else {
            // 설정 무시하고 강제 실행
            switch type {
            case .success:
                completeSuccess()
            case .error:
                completeError()
            case .impact(let style):
                switch style {
                case .light: lightImpact()
                case .medium: mediumImpact()
                case .heavy: heavyImpact()
                case .soft:
                    softImpact()
                case .rigid:
                    rigidImpact()
                @unknown default:
                    mediumImpact() // 향후 추가될 수 있는 케이스에 대한 기본 처리
                }
            case .selection:
                selectionChanged()
            }
        }
    }
}

// MARK: - Feedback Types

public enum FeedbackType {
    case success
    case error
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case selection
}

// MARK: - View Extensions for Haptic Feedback

public extension View {
    /// 탭 시 햅틱 피드백 추가
    func hapticFeedback(
        _ type: FeedbackType = .impact(.medium),
        respectsSettings: Bool = true
    ) -> some View {
        onTapGesture {
            HapticUtils.conditionalFeedback(type: type, respectsSettings: respectsSettings)
        }
    }
    
    /// 성공 햅틱 피드백
    func successFeedback(respectsSettings: Bool = true) -> some View {
        hapticFeedback(.success, respectsSettings: respectsSettings)
    }
    
    /// 에러 햅틱 피드백
    func errorFeedback(respectsSettings: Bool = true) -> some View {
        hapticFeedback(.error, respectsSettings: respectsSettings)
    }
    
    /// 선택 변경 햅틱 피드백
    func selectionFeedback(respectsSettings: Bool = true) -> some View {
        hapticFeedback(.selection, respectsSettings: respectsSettings)
    }
}
