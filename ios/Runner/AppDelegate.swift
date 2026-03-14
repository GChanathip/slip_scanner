import Flutter
import UIKit
import Vision
import Photos

// MARK: - Pre-compiled Regex Patterns (compiled once at launch)
private struct RegexPatterns {
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

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
    private var visionChannel: FlutterMethodChannel?
    private var progressChannel: FlutterMethodChannel?

    private let stateLock = NSLock()
    private var _isCancelled = false
    private var isCancelled: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _isCancelled }
        set { stateLock.lock(); defer { stateLock.unlock() }; _isCancelled = newValue }
    }

    private lazy var maxConcurrentOperations: Int = {
        min(ProcessInfo.processInfo.activeProcessorCount, 6)
    }()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        visionChannel = FlutterMethodChannel(
            name: "com.example.slip_scanner/vision",
            binaryMessenger: controller.binaryMessenger
        )
        progressChannel = FlutterMethodChannel(
            name: "com.example.slip_scanner/progress",
            binaryMessenger: controller.binaryMessenger
        )

        visionChannel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "scanAllPhotos":
                var processedIds: Set<String> = []
                if let args = call.arguments as? [String: Any],
                   let ids = args["processedAssetIds"] as? [String] {
                    processedIds = Set(ids)
                }
                self?.scanAllPhotos(processedAssetIds: processedIds, result: result)
            case "cancelScanning":
                self?.cancelScanning()
                result(true)
            case "getProcessedPhotoIds":
                result([])
            case "scanPaymentSlip":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path required", details: nil))
                    return
                }
                self?.scanPaymentSlip(imagePath: imagePath, result: result)
            case "deleteSlipImage":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path required", details: nil))
                    return
                }
                self?.deleteSlipImage(imagePath: imagePath, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Photo Scanning
    private func scanAllPhotos(processedAssetIds: Set<String>, result: @escaping FlutterResult) {
        cancelScanning()
        isCancelled = false

        let status = PHPhotoLibrary.authorizationStatus()

        guard status == .authorized || status == .limited else {
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            self?.startBackgroundScanning(processedAssetIds: processedAssetIds, result: result)
                        } else {
                            result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
                        }
                    }
                }
            } else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
            }
            return
        }

        startBackgroundScanning(processedAssetIds: processedAssetIds, result: result)
    }

    private func startBackgroundScanning(processedAssetIds: Set<String>, result: @escaping FlutterResult) {
        // Return immediately - don't block platform/UI thread
        result(["status": "started", "message": "Scanning started"])

        // Run on background thread (NOT Task{} which inherits MainActor)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performStreamingScanning(processedAssetIds: processedAssetIds)
        }
    }

    // MARK: - Streaming Scan (real-time progress, NO chunking, NO throttling)
    private func performStreamingScanning(processedAssetIds: Set<String>) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let assets = PHAsset.fetchAssets(with: fetchOptions)
        let totalCount = assets.count

        guard totalCount > 0 else {
            sendProgressFromBackground(total: 0, processed: 0, slipsFound: 0, isComplete: true)
            return
        }

        // Thread-safe counters using lock
        let counterLock = NSLock()
        var processedCount = 0
        var slipsFoundCount = 0

        // Accumulate slips for batch sending (more efficient than one-by-one)
        let slipsLock = NSLock()
        var accumulatedSlips: [[String: Any]] = []

        // Send initial progress
        sendProgressFromBackground(total: totalCount, processed: 0, slipsFound: 0, isComplete: false)

        // OperationQueue for bounded concurrency
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = maxConcurrentOperations
        operationQueue.qualityOfService = .userInitiated

        let completionGroup = DispatchGroup()

        // Add ALL operations at once - OperationQueue handles concurrency
        for i in 0..<totalCount {
            guard !isCancelled else { break }

            let asset = assets.object(at: i)

            // Skip assets already in the database — no OCR needed
            if processedAssetIds.contains(asset.localIdentifier) {
                counterLock.lock()
                processedCount += 1
                let currentProcessed = processedCount
                let currentSlipsFound = slipsFoundCount
                counterLock.unlock()
                sendProgressFromBackground(
                    total: totalCount,
                    processed: currentProcessed,
                    slipsFound: currentSlipsFound,
                    isComplete: false
                )
                continue
            }

            completionGroup.enter()

            operationQueue.addOperation { [weak self] in
                defer { completionGroup.leave() }
                guard let self = self, !self.isCancelled else { return }

                // Process single image with autoreleasepool
                autoreleasepool {
                    let slip = self.processAsset(asset)

                    // Update counters
                    counterLock.lock()
                    processedCount += 1
                    let currentProcessed = processedCount
                    if slip != nil {
                        slipsFoundCount += 1
                    }
                    let currentSlipsFound = slipsFoundCount
                    counterLock.unlock()

                    // Accumulate slip if found
                    if let foundSlip = slip {
                        slipsLock.lock()
                        accumulatedSlips.append(foundSlip)
                        // Send batch every 10 slips for efficiency
                        var slipsToSend: [[String: Any]]? = nil
                        if accumulatedSlips.count >= 10 {
                            slipsToSend = accumulatedSlips
                            accumulatedSlips = []
                        }
                        slipsLock.unlock()

                        if let batch = slipsToSend {
                            self.sendPartialResultsFromBackground(batch)
                        }
                    }

                    // Send progress after EVERY image (no throttling)
                    // DispatchQueue.main.async is non-blocking, won't slow down OCR
                    self.sendProgressFromBackground(
                        total: totalCount,
                        processed: currentProcessed,
                        slipsFound: currentSlipsFound,
                        isComplete: false
                    )
                }
            }
        }

        // Wait for all to complete
        completionGroup.wait()

        // Send remaining slips
        slipsLock.lock()
        let remainingSlips = accumulatedSlips
        slipsLock.unlock()

        if !remainingSlips.isEmpty {
            sendPartialResultsFromBackground(remainingSlips)
        }

        // Send final
        counterLock.lock()
        let finalProcessed = processedCount
        let finalSlipsFound = slipsFoundCount
        counterLock.unlock()

        sendProgressFromBackground(
            total: totalCount,
            processed: finalProcessed,
            slipsFound: finalSlipsFound,
            isComplete: true
        )
    }

    // MARK: - Image Processing
    private func processAsset(_ asset: PHAsset) -> [String: Any]? {
        guard let cgImage = loadImageSync(from: asset) else {
            return nil
        }
        return processImageForPaymentSlip(cgImage: cgImage, assetId: asset.localIdentifier)
    }

    private func loadImageSync(from asset: PHAsset) -> CGImage? {
        var resultImage: CGImage?

        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .fast
        requestOptions.isNetworkAccessAllowed = false

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 512, height: 512),
            contentMode: .aspectFit,
            options: requestOptions
        ) { image, _ in
            resultImage = image?.cgImage
        }

        return resultImage
    }

    // MARK: - Shared OCR Helpers

    /// Perform OCR on a CGImage and return extracted text, amount, and date
    private func recognizeText(from cgImage: CGImage) -> (text: String, amount: Double?, date: String?) {
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

    /// Build a result dictionary from extracted OCR data
    private func buildSlipResult(text: String, amount: Double, date: String?, identifier: String) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        let referenceId = extractReferenceId(text)
        let senderName = extractSenderName(text)
        let receiverName = extractReceiverName(text)
        let time = extractTimeFromText(text)
        let accounts = extractAccountNumbers(text)

        return [
            "text": String(text.prefix(10000)),
            "amount": amount,
            "date": String((date ?? "").prefix(50)),
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

    private func processImageForPaymentSlip(cgImage: CGImage, assetId: String) -> [String: Any]? {
        let (text, amount, date) = recognizeText(from: cgImage)
        guard let foundAmount = amount, foundAmount > 0 else { return nil }
        return buildSlipResult(text: text, amount: foundAmount, date: date, identifier: assetId)
    }

    // MARK: - Callbacks to Flutter (non-blocking)
    private func sendProgressFromBackground(total: Int, processed: Int, slipsFound: Int, isComplete: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.progressChannel?.invokeMethod("onProgress", arguments: [
                "total": total,
                "processed": processed,
                "slipsFound": slipsFound,
                "isComplete": isComplete
            ])
        }
    }

    private func sendPartialResultsFromBackground(_ slips: [[String: Any]]) {
        DispatchQueue.main.async { [weak self] in
            self?.progressChannel?.invokeMethod("onPartialResults", arguments: [
                "type": "partial_results",
                "slips": slips,
                "isComplete": false
            ])
        }
    }

    private func cancelScanning() {
        isCancelled = true
    }

    // MARK: - Single Image Scanning
    private func scanPaymentSlip(imagePath: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
            result(FlutterError(code: "IMAGE_ERROR", message: "Could not load image", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let (text, amount, date) = self.recognizeText(from: cgImage)
            var slipResult = self.buildSlipResult(
                text: text,
                amount: amount ?? 0.0,
                date: date,
                identifier: imagePath
            )
            slipResult["imagePath"] = imagePath

            DispatchQueue.main.async {
                result(slipResult)
            }
        }
    }

    private func deleteSlipImage(imagePath: String, result: @escaping FlutterResult) {
        if imagePath.contains("asset-library://") || imagePath.contains("ph://") {
            result(true)
            return
        }

        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: imagePath) {
                try fileManager.removeItem(atPath: imagePath)
            }
            result(true)
        } catch {
            result(FlutterError(code: "DELETE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Text Extraction
    private func extractAmountFromText(_ text: String) -> Double? {
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

    private func extractDateFromText(_ text: String) -> String? {
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

    private func extractReferenceId(_ text: String) -> String? {
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

    private func extractName(
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

    private func extractSenderName(_ text: String) -> String? {
        extractName(from: text, labelPatterns: RegexPatterns.senderNamePatterns, anchorMatchIndex: 0)
    }

    private func extractReceiverName(_ text: String) -> String? {
        extractName(from: text, labelPatterns: RegexPatterns.receiverNamePatterns, anchorMatchIndex: 1)
    }

    private func extractAccountNumbers(_ text: String) -> [String] {
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

    private func extractTimeFromText(_ text: String) -> String? {
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

    private func containsBuddhistYear(_ dateString: String) -> Bool {
        let range = NSRange(location: 0, length: dateString.count)
        return RegexPatterns.buddhistYearPattern.firstMatch(in: dateString, options: [], range: range) != nil
    }

    private func convertBuddhistToGregorian(_ dateString: String) -> String {
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
