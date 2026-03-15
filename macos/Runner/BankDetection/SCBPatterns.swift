import Foundation

// MARK: - SCB (Siam Commercial Bank) Patterns

/// SCB slip extraction patterns.
/// SCB uses label-based name extraction: จาก/From (sender), ไปยัง/To (receiver).
/// Account masks: xxx-xxx####-# format.
/// Dates: Buddhist Era (subtract 543 for CE).
enum SCBPatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .scb,
        dateFormat: .buddhistEra,
        senderName: senderNamePatterns,
        receiverName: receiverNamePatterns,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns
    )

    // MARK: - Name Patterns (label-based)

    private static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"จาก\n(.*?)(?=\n|xxx)"#, [.dotMatchesLineSeparators]),
            (#"From\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    private static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"ไปยัง\n(.*?)(?=\n|xxx)"#, [.dotMatchesLineSeparators]),
            (#"To\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"xxx-xxx(\d{3,4}-?\d?)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns

    private static let referenceIdPatterns: [NSRegularExpression] = {
        [
            #"รหัสอ้างอิง\s*:?\s*([A-Za-z0-9]+)"#,
            #"Transaction ID:\s*([A-Za-z0-9]+)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
