import Foundation

// MARK: - Bank Pattern Registry

/// Static registry mapping BankType to its BankPatternSet.
/// Adding a new bank = adding one entry here + one new *Patterns.swift file.
class BankPatternRegistry {

    static let patterns: [BankType: BankPatternSet] = [
        .scb: SCBPatterns.patternSet,
        .kbank: KBankPatterns.patternSet,
        .dime: DimePatterns.patternSet,
        .ktb: KTBPatterns.patternSet,
        .gsb: GSBPatterns.patternSet,
        .ttb: TTBPatterns.patternSet,
        // Future banks:
        // .bay: BAYPatterns.patternSet,
        // .bbl: BBLPatterns.patternSet,
    ]

    /// Look up patterns for a bank type. Returns nil for .unknown or unregistered banks.
    static func patterns(for bankType: BankType) -> BankPatternSet? {
        return patterns[bankType]
    }
}
