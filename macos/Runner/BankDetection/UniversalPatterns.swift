import Foundation

// MARK: - Universal Patterns

/// Cross-bank patterns that work regardless of which bank issued the slip.
/// These are used as defaults when a bank's BankPatternSet doesn't provide its own.
struct UniversalPatterns {

    // MARK: - Amount

    static let amountPatterns: [NSRegularExpression] = {
        let patterns = [
            #"จำนวนเงิน\s*([\d,]+\.\d{2})"#,
            #"Amount\s*\n?\s*([\d,]+\.\d{2})"#,
            #"([\d,]+\.\d{2})\s*THB"#,
            #"จำนวน:\s*(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
            #"จำนวน\s+(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
            #"(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
            #"(?:จำนวน|amount|เงิน).*?(\d{1,3}(?:,\d{3})*\.\d{2})"#,
            #"\b(\d{1,3}(?:,\d{3})*\.\d{2})\b"#,
            #"\b([1-9]\d{1,2}\.\d{2})\b"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    static let numberExtractor: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"(\d{1,3}(?:,\d{3})*\.\d{2})"#)
    }()

    // MARK: - Date & Time

    static let dateTimePatterns: [NSRegularExpression] = {
        let patterns = [
            #"(\d{1,2}\s+[^\s]+\s+\d{4})\s*-\s*(\d{1,2}:\d{2})"#,
            #"Date\s+(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})\s+-\s+(\d{1,2}:\d{2}\s+[AP]M)"#,
            #"(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})\s+(\d{1,2}:\d{2})"#,
            #"(\d{1,2}\s+[^\s]+\.?\s+\d{2})\s+(\d{1,2}:\d{2})"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    static let thaiMonthPatterns: [(regex: NSRegularExpression, month: String)] = {
        let months = [
            ("มิ\\.ย\\.", "06"), ("ม\\.ค\\.", "01"), ("ก\\.พ\\.", "02"),
            ("มี\\.ค\\.", "03"), ("เม\\.ย\\.", "04"), ("พ\\.ค\\.", "05"),
            ("ก\\.ค\\.", "07"), ("ส\\.ค\\.", "08"), ("ก\\.ย\\.", "09"),
            ("ต\\.ค\\.", "10"), ("พ\\.ย\\.", "11"), ("ธ\\.ค\\.", "12")
        ]
        return months.compactMap { (pattern, month) in
            guard let regex = try? NSRegularExpression(
                pattern: "(\\d{1,2})\\s*\(pattern)\\s*(\\d{2,4})"
            ) else { return nil }
            return (regex, month)
        }
    }()

    static let datePatterns: [NSRegularExpression] = {
        let patterns = [
            #"\d{1,2}/\d{1,2}/\d{4}"#,
            #"\d{1,2}-\d{1,2}-\d{4}"#,
            #"\d{4}/\d{1,2}/\d{1,2}"#,
            #"\d{4}-\d{1,2}-\d{1,2}"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // MARK: - Buddhist Calendar

    static let buddhistYearPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"25\d{2}|6[0-9]|7[0-9]"#)
    }()

    static let fourDigitBuddhistYear: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"(25\d{2})"#)
    }()

    static let twoDigitBuddhistYear: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\b([6-7]\d)\b"#)
    }()

    // MARK: - Transaction Reference (PromptPay)

    /// PromptPay NITMX-assigned transaction reference: 22–25 digit number, unique per transaction.
    static let transRefPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\b\d{22,25}\b"#)
    }()

    /// Extract PromptPay transaction reference from OCR text.
    static func extractTransRef(_ ocrText: String) -> String? {
        let nsText = ocrText as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = transRefPattern.firstMatch(in: ocrText, options: [], range: range) else {
            return nil
        }
        return nsText.substring(with: match.range)
    }
}
