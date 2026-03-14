import Foundation
import Vision

// MARK: - OCR Service
// Handles Vision text recognition and structured field extraction from OCR output.
class OCRService {

    // MARK: - Core OCR

    func recognizeText(from cgImage: CGImage) -> (text: String, amount: Double?, date: String?) {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var extractedText = ""
        var amount: Double?
        var date: String?

        let request = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let self = self,
                  error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else { return }

            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                let text = topCandidate.string
                extractedText += text + "\n"

                if amount == nil { amount = self.extractAmountFromText(text) }
                if date == nil { date = self.extractDateFromText(text) }
            }

            if amount == nil { amount = self.extractAmountFromText(extractedText) }
            if date == nil { date = self.extractDateFromText(extractedText) }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["th-TH", "en-US"]
        request.usesLanguageCorrection = true

        do {
            try requestHandler.perform([request])
        } catch {
            #if DEBUG
            print("Vision error: \(error)")
            #endif
        }

        return (extractedText, amount, date)
    }

    func buildSlipResult(text: String, amount: Double, date: String?, identifier: String) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        let referenceId = extractReferenceId(text)
        let senderName = extractSenderName(text)
        let receiverName = extractReceiverName(text)
        let time = extractTimeFromText(text)
        let accounts = extractAccountNumbers(text)

        let normalizedDate = date.map { normalizeToISODate($0) } ?? ""

        return [
            "text": String(text.prefix(10000)),
            "amount": amount,
            "date": String(normalizedDate.prefix(50)),
            "assetId": String(identifier.prefix(100)),
            "createdAt": dateFormatter.string(from: Date()),
            "referenceId": referenceId ?? "",
            "senderName": senderName ?? "",
            "receiverName": receiverName ?? "",
            "senderAccount": accounts.count > 0 ? accounts[0] : "",
            "receiverAccount": accounts.count > 1 ? accounts[1] : "",
            "time": time ?? "",
        ]
    }

    func processImageForPaymentSlip(cgImage: CGImage, assetId: String) -> [String: Any]? {
        let (text, amount, date) = recognizeText(from: cgImage)
        guard let foundAmount = amount, foundAmount > 0 else { return nil }
        return buildSlipResult(text: text, amount: foundAmount, date: date, identifier: assetId)
    }

    // MARK: - Amount Extraction

    func extractAmountFromText(_ text: String) -> Double? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        for regex in RegexPatterns.amountPatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let matchedText = nsText.substring(with: match.range)
                let matchRange = NSRange(location: 0, length: matchedText.count)
                if let numberMatch = RegexPatterns.numberExtractor.firstMatch(
                    in: matchedText, options: [], range: matchRange
                ) {
                    let numberString = (matchedText as NSString)
                        .substring(with: numberMatch.range)
                        .replacingOccurrences(of: ",", with: "")
                    if let amount = Double(numberString) {
                        return amount
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Date Extraction

    func extractDateFromText(_ text: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        // Try combined date-time patterns first (SCB, Make, K Plus, Dime)
        for regex in RegexPatterns.dateTimePatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1 {
                let dateString = nsText.substring(with: match.range(at: 1))
                if containsBuddhistYear(dateString) {
                    return convertBuddhistToGregorian(dateString)
                }
                return dateString
            }
        }

        for (regex, _) in RegexPatterns.thaiMonthPatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let dateString = nsText.substring(with: match.range)
                if containsBuddhistYear(dateString) {
                    return convertBuddhistToGregorian(dateString)
                }
                return dateString
            }
        }

        for regex in RegexPatterns.datePatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                return nsText.substring(with: match.range)
            }
        }
        return nil
    }

    // MARK: - Reference / Account / Name Extraction

    func extractReferenceId(_ text: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        for regex in RegexPatterns.referenceIdPatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1 {
                return nsText.substring(with: match.range(at: 1))
            }
        }
        return nil
    }

    func extractName(
        from text: String,
        labelPatterns: [NSRegularExpression],
        anchorMatchIndex: Int
    ) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        // Try label-based patterns first (SCB/Dime)
        for regex in labelPatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1 {
                let name = nsText.substring(with: match.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { return name }
            }
        }

        // Try K Plus anchor (name 2 lines above mask)
        let kplusMatches = RegexPatterns.kbankPlusNamePattern.matches(in: text, options: [], range: range)
        if kplusMatches.count > anchorMatchIndex, kplusMatches[anchorMatchIndex].numberOfRanges > 1 {
            let name = nsText.substring(with: kplusMatches[anchorMatchIndex].range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { return name }
        }

        // Try Make anchor (name directly above mask)
        let makeMatches = RegexPatterns.kbankMakeNamePattern.matches(in: text, options: [], range: range)
        if makeMatches.count > anchorMatchIndex, makeMatches[anchorMatchIndex].numberOfRanges > 1 {
            let name = nsText.substring(with: makeMatches[anchorMatchIndex].range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { return name }
        }

        return nil
    }

    func extractSenderName(_ text: String) -> String? {
        extractName(from: text, labelPatterns: RegexPatterns.senderNamePatterns, anchorMatchIndex: 0)
    }

    func extractReceiverName(_ text: String) -> String? {
        extractName(from: text, labelPatterns: RegexPatterns.receiverNamePatterns, anchorMatchIndex: 1)
    }

    func extractAccountNumbers(_ text: String) -> [String] {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        // Try each pattern; for the first one that matches, return all group 1 captures
        for regex in RegexPatterns.accountNumberPatterns {
            let matches = regex.matches(in: text, options: [], range: range)
            if !matches.isEmpty {
                return matches.compactMap { match in
                    guard match.numberOfRanges > 1 else { return nil }
                    return nsText.substring(with: match.range(at: 1))
                }
            }
        }
        return []
    }

    func extractTimeFromText(_ text: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        for regex in RegexPatterns.dateTimePatterns {
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 2 {
                return nsText.substring(with: match.range(at: 2))
            }
        }
        return nil
    }

    // MARK: - Buddhist Calendar Helpers

    func containsBuddhistYear(_ dateString: String) -> Bool {
        let range = NSRange(location: 0, length: dateString.count)
        return RegexPatterns.buddhistYearPattern.firstMatch(in: dateString, options: [], range: range) != nil
    }

    // MARK: - Cached Date Formatters (expensive to create, reuse across calls)

    private static let isoOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dateInputFormatters: [DateFormatter] = {
        let locale = Locale(identifier: "en_US")
        let formats = [
            "dd/MM/yyyy", "d/M/yyyy",
            "yyyy/MM/dd",
            "yyyy-MM-dd",
            "dd-MM-yyyy", "d-M-yyyy",
            "dd MMM yyyy", "d MMM yyyy",
            "dd MMMM yyyy", "d MMMM yyyy",
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.locale = locale
            f.dateFormat = format
            return f
        }
    }()

    /// Normalize any extracted date string to ISO `yyyy-MM-dd` format.
    /// Returns the original string unchanged if no known format is recognized.
    func normalizeToISODate(_ dateStr: String) -> String {
        let trimmed = dateStr.trimmingCharacters(in: .whitespacesAndNewlines)

        for formatter in OCRService.dateInputFormatters {
            if let date = formatter.date(from: trimmed) {
                return OCRService.isoOutputFormatter.string(from: date)
            }
        }
        return trimmed
    }

    func convertBuddhistToGregorian(_ dateString: String) -> String {
        let monthMap = [
            "ม.ค.": "01", "ก.พ.": "02", "มี.ค.": "03", "เม.ย.": "04",
            "พ.ค.": "05", "มิ.ย.": "06", "ก.ค.": "07", "ส.ค.": "08",
            "ก.ย.": "09", "ต.ค.": "10", "พ.ย.": "11", "ธ.ค.": "12"
        ]

        var result = dateString
        for (thai, num) in monthMap {
            result = result.replacingOccurrences(of: thai, with: "/\(num)/")
        }

        let nsResult = result as NSString
        let range = NSRange(location: 0, length: nsResult.length)

        if let match = RegexPatterns.fourDigitBuddhistYear.firstMatch(in: result, options: [], range: range) {
            let year = nsResult.substring(with: match.range)
            if let y = Int(year) {
                result = result.replacingOccurrences(of: year, with: String(y - 543))
            }
        }

        let nsResult2 = result as NSString
        let range2 = NSRange(location: 0, length: nsResult2.length)

        if let match = RegexPatterns.twoDigitBuddhistYear.firstMatch(in: result, options: [], range: range2) {
            let shortYear = nsResult2.substring(with: match.range)
            if let y = Int(shortYear) {
                result = result.replacingOccurrences(of: shortYear, with: String(2500 + y - 543))
            }
        }

        return result.replacingOccurrences(of: " ", with: "")
    }
}
