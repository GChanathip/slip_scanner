import Foundation

// MARK: - KBank (Kasikorn Bank) Patterns

/// KBank slip extraction patterns covering both Make by KBank and K Plus variants.
/// KBank uses positional name extraction: name appears above the account mask line.
///   - Make: name is directly above mask (1 line)
///   - K Plus: name is 2 lines above mask (skip bank name line)
/// Positional: match[0] = sender, match[1] = receiver.
/// Account masks: xxx-x-x####-x format.
/// Dates: Buddhist Era.
enum KBankPatterns {

    static let patternSet: BankPatternSet = BankPatternSet(
        bankType: .kbank,
        dateFormat: .buddhistEra,
        senderAccount: accountPatterns,
        receiverAccount: accountPatterns,
        referenceId: referenceIdPatterns,
        positionalNamePatterns: positionalNamePatterns
    )

    // MARK: - Positional Name Patterns

    /// K Plus pattern (2 lines above mask) tried first, then Make pattern (1 line above).
    /// match[0] = sender, match[1] = receiver.
    private static let positionalNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            // K Plus: name → bank name → mask
            (#"(.*?)\n(?:.*?)\n(?=xxx-x-x\d{4}-x)"#, [.dotMatchesLineSeparators]),
            // Make: name → mask
            (#"(.*?)\n(?=xxx-x-x\d{4}-x)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // MARK: - Account Patterns

    private static let accountPatterns: [NSRegularExpression] = {
        [
            #"xxx-x-x(\d{4})-x"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Reference ID Patterns

    private static let referenceIdPatterns: [NSRegularExpression] = {
        [
            #"เลขที่รายการ:?\s*([A-Za-z0-9]+)"#,
            #"Slip ID\s+(\d+)"#,
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
