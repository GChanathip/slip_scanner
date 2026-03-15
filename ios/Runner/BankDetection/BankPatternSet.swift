import Foundation

// MARK: - Bank Pattern Set

/// A collection of regex patterns for extracting fields from a specific bank's payment slip.
/// Each bank provides its own pattern set via a dedicated `*Patterns.swift` file.
struct BankPatternSet {
    let bankType: BankType
    let dateFormat: DateFormat

    /// Amount patterns (ordered by specificity). Nil = use universal amount patterns.
    let amount: [NSRegularExpression]?

    /// Date/time patterns (ordered by specificity). Nil = use universal date patterns.
    let date: [NSRegularExpression]?

    /// Sender name patterns. For label-based banks (SCB, Dime), these match directly.
    let senderName: [NSRegularExpression]

    /// Receiver name patterns. For label-based banks (SCB, Dime), these match directly.
    let receiverName: [NSRegularExpression]

    /// Sender account number patterns.
    let senderAccount: [NSRegularExpression]

    /// Receiver account number patterns.
    let receiverAccount: [NSRegularExpression]

    /// Reference ID / transaction ID patterns.
    let referenceId: [NSRegularExpression]

    /// For banks with positional name extraction (KBank), a pattern whose matches
    /// are indexed: match[0] = sender, match[1] = receiver.
    /// When set, this is tried before senderName/receiverName label patterns.
    let positionalNamePatterns: [NSRegularExpression]

    init(
        bankType: BankType,
        dateFormat: DateFormat,
        amount: [NSRegularExpression]? = nil,
        date: [NSRegularExpression]? = nil,
        senderName: [NSRegularExpression] = [],
        receiverName: [NSRegularExpression] = [],
        senderAccount: [NSRegularExpression] = [],
        receiverAccount: [NSRegularExpression] = [],
        referenceId: [NSRegularExpression] = [],
        positionalNamePatterns: [NSRegularExpression] = []
    ) {
        self.bankType = bankType
        self.dateFormat = dateFormat
        self.amount = amount
        self.date = date
        self.senderName = senderName
        self.receiverName = receiverName
        self.senderAccount = senderAccount
        self.receiverAccount = receiverAccount
        self.referenceId = referenceId
        self.positionalNamePatterns = positionalNamePatterns
    }
}
