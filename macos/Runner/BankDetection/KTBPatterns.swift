import Foundation

// MARK: - KTB (Krungthai Bank) Patterns

/// KTB slip extraction patterns covering both the Krungthai Bank app and เป๋าตัง variants.
/// Dates: Buddhist Era (subtract 543 for CE).
/// Reference ID: positional — appears as a standalone alphanumeric token on its own line
///   immediately after the transfer success header, with no label prefix.
///   Primary pattern: token on the line right after โอนเงินสำเร็จ.
///   Fallback pattern: 2–3 uppercase-letter prefix followed by 8+ digits (e.g. FT67015...).
/// Account masks: xxx-x-x####-x format. Shared pattern applied in order (sender first).
enum KTBPatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .ktb,
        dateFormat: .buddhistEra,
        senderName: senderNamePatterns,
        receiverName: receiverNamePatterns,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns
    )

    // MARK: - Name Patterns (label-based)

    /// ชื่อผู้โอน (sender name) appears on the line following the label.
    private static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"ชื่อผู้โอน\n(.*)"#, []),
            (#"ชื่อผู้โอน\s*:\s*(.*)"#, []),
            (#"ผู้โอน\n(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    /// ชื่อผู้รับ (receiver name) appears on the line following the label.
    private static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"ชื่อผู้รับ\n(.*)"#, []),
            (#"ชื่อผู้รับ\s*:\s*(.*)"#, []),
            (#"ผู้รับ\n(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    /// KTB uses xxx-x-x####-x account masks (same structure as KBank).
    /// Captures the 4 visible digits (last group before the trailing -x).
    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"xxx-x-x(\d{4})-x"#,
            #"xxx-x-(\d{5}-\d)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns (positional)

    /// KTB reference IDs have no label prefix. Two complementary strategies:
    /// 1. Positional: token on the line immediately after a transfer-success header.
    /// 2. Format match: 2–3 uppercase letters followed by 8+ digits (e.g. FT67015ABCDE12).
    private static let referenceIdPatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            // Positional: standalone token right after โอนเงินสำเร็จ
            (#"(?:โอนเงินสำเร็จ|โอนเงิน)\n([A-Za-z0-9]{8,20})(?:\n|$)"#, []),
            // Format match: uppercase-letter prefix + digits (FT/KTB prefix style)
            (#"(?m)^([A-Z]{2,3}\d{8,16})$"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()
}
