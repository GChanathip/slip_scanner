import Foundation

// MARK: - Pre-compiled Regex Patterns (compiled once at launch)
struct RegexPatterns {
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

    static let buddhistYearPattern: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"25\d{2}|6[0-9]|7[0-9]"#)
    }()

    static let fourDigitBuddhistYear: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"(25\d{2})"#)
    }()

    static let twoDigitBuddhistYear: NSRegularExpression = {
        try! NSRegularExpression(pattern: #"\b([6-7]\d)\b"#)
    }()

    // MARK: - Multi-Bank Patterns

    // Reference / Transaction ID (SCB, K Plus, Make by KBank, Dime)
    static let referenceIdPatterns: [NSRegularExpression] = {
        let patterns = [
            #"รหัสอ้างอิง\s*:?\s*([A-Za-z0-9]+)"#,
            #"เลขที่รายการ:?\s*([A-Za-z0-9]+)"#,
            #"Transaction ID:\s*([A-Za-z0-9]+)"#,
            #"Slip ID\s+(\d+)"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // Sender Name - label-based (SCB, Dime)
    static let senderNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"จาก\n(.*?)(?=\n|xxx)"#, [.dotMatchesLineSeparators]),
            (#"From\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // Receiver Name - label-based (SCB, Dime)
    static let receiverNamePatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"ไปยัง\n(.*?)(?=\n|xxx)"#, [.dotMatchesLineSeparators]),
            (#"To\s*\n?(.+?)(?=\n|x-)"#, [.dotMatchesLineSeparators]),
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    // KBank Make: name is directly above account mask
    static let kbankMakeNamePattern: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(.*?)\n(?=xxx-x-x\d{4}-x)"#,
            options: [.dotMatchesLineSeparators]
        )
    }()

    // K Plus: name is TWO lines above mask (skip bank name line)
    static let kbankPlusNamePattern: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(.*?)\n(?:.*?)\n(?=xxx-x-x\d{4}-x)"#,
            options: [.dotMatchesLineSeparators]
        )
    }()

    // Account Number masks (SCB, KBank Make/K Plus, Dime)
    static let accountNumberPatterns: [NSRegularExpression] = {
        let patterns = [
            #"xxx-xxx(\d{3,4}-?\d?)"#,
            #"xxx-x-x(\d{4})-x"#,
            #"x-(\d{4})"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    // Date-Time combined patterns (group1=date, group2=time)
    static let dateTimePatterns: [NSRegularExpression] = {
        let patterns = [
            #"(\d{1,2}\s+[^\s]+\s+\d{4})\s*-\s*(\d{1,2}:\d{2})"#,
            #"Date\s+(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})\s+-\s+(\d{1,2}:\d{2}\s+[AP]M)"#,
            #"(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})\s+(\d{1,2}:\d{2})"#,
            #"(\d{1,2}\s+[^\s]+\.?\s+\d{2})\s+(\d{1,2}:\d{2})"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()
}
