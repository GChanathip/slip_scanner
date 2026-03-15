import Foundation

// MARK: - GSB (Government Savings Bank) Patterns

/// GSB slip extraction patterns for the MyMo (ออมสิน My Mobile) app.
/// Dates: Buddhist Era. GSB date format is `DD/MM/YYYY HH:MM` — exactly 15 chars
///   when the day is two digits (e.g. "15/01/2567 14:30"). Universal B.E. date
///   patterns handle conversion; no custom date regex required.
/// Name labels: ผู้โอน / ผู้รับ (with optional ชื่อ prefix or colon suffix).
/// Reference ID: labeled with เลขที่อ้างอิง, รหัสอ้างอิง, or เลขที่รายการ.
/// Account masks: xxx-x-x#####-x format (shared pattern; first match = sender).
enum GSBPatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .gsb,
        dateFormat: .buddhistEra,
        senderName: senderNamePatterns,
        receiverName: receiverNamePatterns,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns
    )

    // MARK: - Name Patterns (label-based)

    /// GSB uses ผู้โอน (sender) with optional ชื่อ prefix or colon suffix.
    private static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"(?:ชื่อ)?ผู้โอน\s*:?\s*(.*)"#, []),
            (#"ผู้ส่ง\s*:?\s*(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    /// GSB uses ผู้รับ (receiver) with optional ชื่อ prefix, ผู้รับโอน variant.
    private static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"(?:ชื่อ)?ผู้รับ\s*:?\s*(.*)"#, []),
            (#"ผู้รับโอน\s*:?\s*(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    /// GSB account masks follow xxx-x-x#####-x format. Captures 5 visible digits.
    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"xxx-x-x(\d{5})-x"#,
            #"xxx-x-(\d{5}-\d)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns (label-based)

    private static let referenceIdPatterns: [NSRegularExpression] = {
        [
            #"(?:เลขที่อ้างอิง|รหัสอ้างอิง)\s*:?\s*([A-Za-z0-9]+)"#,
            #"เลขที่รายการ\s*:?\s*([A-Za-z0-9]+)"#,
            #"(?:Ref|Transaction\s*(?:ID|No))\s*\.?\s*:?\s*([A-Za-z0-9]+)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
