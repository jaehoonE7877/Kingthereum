#!/usr/bin/env swift

import Foundation

// MARK: - Color Conversion Script for Kingthereum
// 하드코딩된 색상을 KingDesignTokens 시스템으로 변환

struct ColorReplacement {
    let pattern: String
    let replacement: String
    let description: String
}

// 색상 변환 규칙 정의
let colorReplacements: [ColorReplacement] = [
    // Basic Colors
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.white\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.systemWhite)",
        description: "White text → System white (adaptive)"
    ),
    ColorReplacement(
        pattern: "\\.foregroundColor\\(Color\\.white\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.systemWhite)",
        description: "Color.white → System white"
    ),
    ColorReplacement(
        pattern: "\\.background\\(Color\\.white\\)",
        replacement: ".background(KingDesignTokens.Colors.systemWhite)",
        description: "White background → System white"
    ),
    ColorReplacement(
        pattern: "\\.background\\(\\.white\\)",
        replacement: ".background(KingDesignTokens.Colors.systemWhite)",
        description: "White background shorthand → System white"
    ),
    
    // Black Colors
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.black\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.primaryText)",
        description: "Black text → Primary text"
    ),
    ColorReplacement(
        pattern: "\\.foregroundColor\\(Color\\.black\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.primaryText)",
        description: "Color.black → Primary text"
    ),
    ColorReplacement(
        pattern: "\\.background\\(Color\\.black\\)",
        replacement: ".background(KingDesignTokens.Colors.systemBlack)",
        description: "Black background → System black"
    ),
    
    // Red Colors
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.red\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.error)",
        description: "Red text → Error color"
    ),
    ColorReplacement(
        pattern: "\\.foregroundColor\\(Color\\.red\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.error)",
        description: "Color.red → Error color"
    ),
    
    // System Colors
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.primary\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.primary)",
        description: "Primary text → Design token primary"
    ),
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.secondary\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.secondaryText)",
        description: "Secondary text → Design token secondary"
    ),
    
    // Background Colors with Opacity
    ColorReplacement(
        pattern: "\\.background\\(Color\\.black\\.opacity\\(([0-9.]+)\\)\\)",
        replacement: ".background(KingDesignTokens.Colors.systemBlack.opacity($1))",
        description: "Black opacity background → System black with opacity"
    ),
    ColorReplacement(
        pattern: "\\.background\\(Color\\.white\\.opacity\\(([0-9.]+)\\)\\)",
        replacement: ".background(KingDesignTokens.Colors.systemWhite.opacity($1))",
        description: "White opacity background → System white with opacity"
    ),
    
    // Clear Colors
    ColorReplacement(
        pattern: "\\.background\\(Color\\.clear\\)",
        replacement: ".background(KingDesignTokens.Colors.clear)",
        description: "Clear background → Design token clear"
    ),
    ColorReplacement(
        pattern: "\\.fill\\(Color\\.clear\\)",
        replacement: ".fill(KingDesignTokens.Colors.clear)",
        description: "Clear fill → Design token clear"
    ),
    
    // Stroke/Border Colors
    ColorReplacement(
        pattern: "\\.stroke\\(Color\\.white\\.opacity\\(([0-9.]+)\\)",
        replacement: ".stroke(KingDesignTokens.Colors.outline.opacity($1)",
        description: "White stroke with opacity → Outline with opacity"
    ),
    
    // Orange/Yellow colors (likely warnings)
    ColorReplacement(
        pattern: "\\.foregroundColor\\(\\.orange\\)",
        replacement: ".foregroundColor(KingDesignTokens.Colors.warning)",
        description: "Orange text → Warning color"
    )
]

// 파일 확장자 필터
let swiftFileExtensions = ["swift"]

func findSwiftFiles(in directory: String) -> [String] {
    let fileManager = FileManager.default
    var swiftFiles: [String] = []
    
    if let enumerator = fileManager.enumerator(atPath: directory) {
        for case let file as String in enumerator {
            if swiftFileExtensions.contains(where: { file.hasSuffix(".\($0)") }) {
                swiftFiles.append("\(directory)/\(file)")
            }
        }
    }
    
    return swiftFiles
}

func processFile(_ filePath: String, dryRun: Bool = false) -> (replacements: Int, changes: [String]) {
    guard let content = try? String(contentsOfFile: filePath) else {
        print("❌ 파일을 읽을 수 없습니다: \(filePath)")
        return (0, [])
    }
    
    var modifiedContent = content
    var totalReplacements = 0
    var changes: [String] = []
    
    for replacement in colorReplacements {
        let regex = try! NSRegularExpression(pattern: replacement.pattern, options: [])
        let range = NSRange(modifiedContent.startIndex..<modifiedContent.endIndex, in: modifiedContent)
        let matches = regex.matches(in: modifiedContent, options: [], range: range)
        
        if !matches.isEmpty {
            let count = matches.count
            totalReplacements += count
            changes.append("  • \(replacement.description): \(count)개")
            
            modifiedContent = regex.stringByReplacingMatches(
                in: modifiedContent,
                options: [],
                range: range,
                withTemplate: replacement.replacement
            )
        }
    }
    
    // 변경사항이 있고 실제 실행 모드인 경우 파일에 쓰기
    if totalReplacements > 0 && !dryRun {
        do {
            try modifiedContent.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("❌ 파일 쓰기 실패: \(filePath) - \(error)")
        }
    }
    
    return (totalReplacements, changes)
}

func main() {
    let arguments = CommandLine.arguments
    let dryRun = arguments.contains("--dry-run")
    let projectPath = arguments.count > 1 ? arguments[1] : "."
    
    print("🎨 Kingthereum 하드코딩 색상 자동 변환 스크립트")
    print("📍 프로젝트 경로: \(projectPath)")
    print("🔧 모드: \(dryRun ? "미리보기" : "실제 변환")")
    print()
    
    let swiftFiles = findSwiftFiles(in: projectPath)
    print("📁 발견된 Swift 파일: \(swiftFiles.count)개")
    print()
    
    var totalFilesChanged = 0
    var totalReplacements = 0
    
    for filePath in swiftFiles {
        let (replacements, changes) = processFile(filePath, dryRun: dryRun)
        
        if replacements > 0 {
            totalFilesChanged += 1
            totalReplacements += replacements
            
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            print("📝 \(fileName)")
            print("  → \(replacements)개 변환")
            for change in changes {
                print(change)
            }
            print()
        }
    }
    
    // 결과 요약
    print("✅ 변환 완료!")
    print("📊 요약:")
    print("  • 변경된 파일: \(totalFilesChanged)개")
    print("  • 총 변환 수: \(totalReplacements)개")
    
    if dryRun {
        print()
        print("💡 실제 변환을 실행하려면 --dry-run 옵션을 제거하세요")
        print("사용법: swift FixHardcodedColors.swift [프로젝트경로]")
    } else {
        print()
        print("🎉 하드코딩된 색상이 KingDesignTokens으로 성공적으로 변환되었습니다!")
        print("⚠️  변경사항을 검토하고 테스트해주세요.")
    }
}

main()