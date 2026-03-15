import Foundation

// MARK: - TTB (TMBThanachart) Patterns

/// ttb slip extraction patterns for both ttb touch (new brand) and legacy TMB Internet
/// Banking variants. Dual branding means two labeling conventions must be handled:
///
/// - **ttb touch style:** `ชื่อบัญชีผู้โอน` / `ชื่อบัญชีผู้รับ` on own line, name follows.
/// - **TMB legacy style:** `จาก` / `ไปยัง` on own line, name follows (matches SCB/Dime style).
/// - **Generic Thai labels:** `ผู้โอน` / `ผู้รับ` with optional colon — fallback.
///
/// Dates: Buddhist Era. Text-dense OCR noise is common; patterns favor specificity.
/// Reference ID: labeled — `หมายเลขรายการ` / `เลขที่รายการ` / `รหัสอ้างอิง`.
/// Account masks: xxx-x-x####-x format.
enum TTBPatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .ttb,
        dateFormat: .buddhistEra,
        senderName: senderNamePatterns,
        receiverName: receiverNamePatterns,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns
    )

    // MARK: - Name Patterns (dual-brand label handling)

    private static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            // ttb touch: dedicated account name label
            (#"ชื่อบัญชีผู้โอน\n(.*)"#, []),
            // TMB legacy: จาก (same structure as SCB/Dime)
            (#"จาก\n(.*)"#, []),
            // Generic Thai label with optional colon (fallback)
            (#"(?:ชื่อ)?ผู้โอน\s*:?\s*(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    private static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            // ttb touch: dedicated account name label
            (#"ชื่อบัญชีผู้รับ\n(.*)"#, []),
            // TMB legacy: ไปยัง
            (#"ไปยัง\n(.*)"#, []),
            // Generic Thai label with optional colon (fallback)
            (#"(?:ชื่อ)?ผู้รับ\s*:?\s*(.*)"#, []),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"xxx-x-x(\d{4})-x"#,
            #"xxx-x-(\d{5}-\d)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns (labeled)

    private static let referenceIdPatterns: [NSRegularExpression] = {
        [
            #"(?:หมายเลขรายการ|เลขที่รายการ)\s*:?\s*([A-Za-z0-9]+)"#,
            #"(?:รหัสอ้างอิง|เลขที่อ้างอิง)\s*:?\s*([A-Za-z0-9]+)"#,
            #"(?:Ref|Transaction\s*(?:ID|No))\s*\.?\s*:?\s*([A-Za-z0-9]+)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
