import Foundation

// MARK: - Bank Type

/// Identifies the bank that issued a payment slip.
/// Used by BankDetector to classify OCR text before field extraction.
enum BankType: String, Codable {
    case scb        // ไทยพาณิชย์ (Siam Commercial Bank)
    case kbank      // กสิกรไทย (Make by KBank / K Plus)
    case dime       // Dime
    case bay        // กรุงศรีอยุธยา (Krungsri)
    case bbl        // กรุงเทพ (Bangkok Bank)
    case ktb        // กรุงไทย (Krungthai)
    case gsb        // ออมสิน (Government Savings Bank)
    case ttb        // ทีเอ็มบีธนชาต (TMBThanachart)
    case unknown    // Fallback — attempt universal patterns + LLM
}

// MARK: - Date Format

/// How dates appear on slips from this bank.
enum DateFormat {
    case buddhistEra   // B.E. year (subtract 543 for CE) — SCB, KBank, Dime, BAY, KTB, GSB, ttb
    case gregorian     // CE year — BBL
}
