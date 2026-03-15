import Foundation

// MARK: - Bank Detector

/// Detects which bank issued a payment slip by running anchor patterns against OCR text.
/// Anchors are simple string/regex matches — not full field extraction.
/// Returns the first matching BankType (priority-ordered), or .unknown if none match.
class BankDetector {

    /// Anchor entry: a case-insensitive pattern to search for, mapped to a BankType.
    private struct Anchor {
        let bankType: BankType
        let pattern: NSRegularExpression
    }

    /// Priority-ordered anchor patterns. Checked top-to-bottom; first match wins.
    /// More specific patterns come before generic ones.
    private static let anchors: [Anchor] = {
        let definitions: [(BankType, String)] = [
            // SCB
            (.scb, #"ธนาคารไทยพาณิชย์"#),
            (.scb, #"\bSCB\b"#),
            (.scb, #"Siam Commercial Bank"#),

            // KBank (Make by KBank / K Plus)
            (.kbank, #"MAKE by KBank"#),
            (.kbank, #"Make by KBank"#),
            (.kbank, #"K PLUS"#),
            (.kbank, #"ธนาคารกสิกรไทย"#),

            // Dime
            (.dime, #"\bDime\b"#),

            // BAY (Krungsri) — placeholder for future
            (.bay, #"\bBAY\b"#),
            (.bay, #"ธนาคารกรุงศรีอยุธยา"#),
            (.bay, #"Krungsri"#),

            // BBL (Bangkok Bank) — placeholder for future
            (.bbl, #"BANGKOK BANK"#),
            (.bbl, #"ธนาคารกรุงเทพ"#),

            // KTB (Krungthai) — placeholder for future
            (.ktb, #"ธนาคารกรุงไทย"#),
            (.ktb, #"Krungthai"#),
            (.ktb, #"เป๋าตัง"#),

            // GSB (Government Savings Bank) — placeholder for future
            (.gsb, #"ธนาคารออมสิน"#),
            (.gsb, #"\bGSB\b"#),

            // ttb (TMBThanachart) — placeholder for future
            (.ttb, #"\bttb\b"#),
            (.ttb, #"\bTMB\b"#),
            (.ttb, #"ทีเอ็มบีธนชาต"#),
            (.ttb, #"TMBThanachart"#),
        ]

        return definitions.compactMap { (bankType, pattern) in
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else { return nil }
            return Anchor(bankType: bankType, pattern: regex)
        }
    }()

    /// Detect bank type from OCR text. Returns .unknown if no anchor matches.
    ///
    /// Uses position-weighted scoring: all anchors are run against the full text and the
    /// bank whose anchor matched at the earliest character offset wins. This correctly
    /// handles cross-bank transfer slips where the issuing bank's name appears in the
    /// header (top of text) and the receiver bank's name appears later in the body.
    /// Ties are broken by anchor priority order (list order above).
    static func detect(_ ocrText: String) -> BankType {
        let nsText = ocrText as NSString
        let range = NSRange(location: 0, length: nsText.length)

        var bestBank: BankType = .unknown
        var bestPosition: Int = .max
        var bestAnchorIndex: Int = .max

        for (anchorIndex, anchor) in anchors.enumerated() {
            guard let match = anchor.pattern.firstMatch(in: ocrText, options: [], range: range) else {
                continue
            }
            let position = match.range.location
            if position < bestPosition || (position == bestPosition && anchorIndex < bestAnchorIndex) {
                bestPosition = position
                bestAnchorIndex = anchorIndex
                bestBank = anchor.bankType
            }
        }

        return bestBank
    }
}
