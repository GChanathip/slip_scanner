import Foundation

// MARK: - Dime Patterns

/// Dime slip extraction patterns.
/// Dime uses label-based name extraction (จาก/ไปยัง), similar to SCB.
/// Account masks: x-#### format.
/// Dates: Buddhist Era.
enum DimePatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .dime,
        dateFormat: .buddhistEra,
        senderName: senderNamePatterns,
        receiverName: receiverNamePatterns,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns
    )

    // MARK: - Name Patterns (label-based, same as SCB)

    private static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"จาก\n(.*?)(?=\n|xxx|x-)"#, [.dotMatchesLineSeparators]),
            (#"From\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    private static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"ไปยัง\n(.*?)(?=\n|xxx|x-)"#, [.dotMatchesLineSeparators]),
            (#"To\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"x-(\d{4})"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns

    private static let referenceIdPatterns: [NSRegularExpression] = {
        [
            #"รหัสอ้างอิง\s*:?\s*([A-Za-z0-9]+)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
