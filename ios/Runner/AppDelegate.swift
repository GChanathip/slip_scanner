import Flutter
import UIKit
import Vision
import Photos

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
  // Cached method channels
  private var visionChannel: FlutterMethodChannel?
  private var progressChannel: FlutterMethodChannel?

  // Scanning state - thread-safe access via lock
  private let stateLock = NSLock()
  private var _isCancelled = false
  private var isCancelled: Bool {
    get { stateLock.lock(); defer { stateLock.unlock() }; return _isCancelled }
    set { stateLock.lock(); defer { stateLock.unlock() }; _isCancelled = newValue }
  }

  // MARK: - Application Lifecycle
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Create and cache method channels once
    visionChannel = FlutterMethodChannel(name: "com.example.slip_scanner/vision",
                                         binaryMessenger: controller.binaryMessenger)
    progressChannel = FlutterMethodChannel(name: "com.example.slip_scanner/progress",
                                           binaryMessenger: controller.binaryMessenger)

    visionChannel?.setMethodCallHandler({ [weak self] (call, result) in
      switch call.method {
      case "scanAllPhotos":
        self?.scanAllPhotos(result: result)
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
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Photo Scanning (Fire-and-Forget Pattern)
  private func scanAllPhotos(result: @escaping FlutterResult) {
    // Cancel any existing scan
    cancelScanning()
    isCancelled = false

    // Check photo library authorization
    let status = PHPhotoLibrary.authorizationStatus()

    guard status == .authorized || status == .limited else {
      if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
          DispatchQueue.main.async {
            if newStatus == .authorized || newStatus == .limited {
              self?.startBackgroundScanning(result: result)
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

    startBackgroundScanning(result: result)
  }

  private func startBackgroundScanning(result: @escaping FlutterResult) {
    // RETURN IMMEDIATELY - don't block platform/UI thread!
    result(["status": "started", "message": "Scanning started"])

    // Do ALL work on background queue - completely off platform thread
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.performBackgroundScanning()
    }
  }

  // MARK: - Background Scanning (runs entirely on background thread)
  private func performBackgroundScanning() {
    // Fetch all photos
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

    let assets = PHAsset.fetchAssets(with: fetchOptions)
    let totalCount = assets.count

    // Send initial progress
    sendProgressFromBackground(total: totalCount, processed: 0, slipsFound: 0, isComplete: false)

    // Process in optimized chunks with concurrent processing
    let chunkSize = 25
    var processedCount = 0
    var totalSlipsFound = 0

    for chunkStart in stride(from: 0, to: totalCount, by: chunkSize) {
      // Check cancellation at chunk boundary
      guard !isCancelled else {
        #if DEBUG
        print("🛑 Scanning cancelled at chunk \(chunkStart)")
        #endif
        break
      }

      // Process chunk with autoreleasepool for memory management
      autoreleasepool {
        let chunkEnd = min(chunkStart + chunkSize, totalCount)
        var chunkSlips: [[String: Any]] = []

        // Use DispatchGroup for concurrent processing within chunk
        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.slip_scanner.chunk", attributes: .concurrent)
        let slipsLock = NSLock()
        let processedLock = NSLock()
        var chunkProcessed = 0

        for i in chunkStart..<chunkEnd {
          // Check cancellation before each image
          guard !isCancelled else { break }

          group.enter()
          concurrentQueue.async { [weak self] in
            defer { group.leave() }
            guard let self = self, !self.isCancelled else { return }

            let asset = assets.object(at: i)
            if let slip = self.processAssetSync(asset) {
              slipsLock.lock()
              chunkSlips.append(slip)
              slipsLock.unlock()
            }

            processedLock.lock()
            chunkProcessed += 1
            processedLock.unlock()
          }
        }

        // Wait for chunk to complete
        group.wait()

        // Update totals
        processedCount += chunkProcessed
        totalSlipsFound += chunkSlips.count

        // Send partial results for this chunk
        if !chunkSlips.isEmpty {
          sendPartialResultsFromBackground(chunkSlips)
        }

        // Send progress update after each chunk
        sendProgressFromBackground(
          total: totalCount,
          processed: processedCount,
          slipsFound: totalSlipsFound,
          isComplete: false
        )
      }
      // Memory released here after autoreleasepool
    }

    // Send completion
    sendProgressFromBackground(
      total: totalCount,
      processed: processedCount,
      slipsFound: totalSlipsFound,
      isComplete: true
    )

    #if DEBUG
    print("✅ Scanning complete: \(processedCount)/\(totalCount) processed, \(totalSlipsFound) slips found")
    #endif
  }

  // MARK: - Image Processing (synchronous, called from background thread)
  private func processAssetSync(_ asset: PHAsset) -> [String: Any]? {
    // Load image synchronously (we're already on background thread)
    var resultImage: CGImage?
    let semaphore = DispatchSemaphore(value: 0)

    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = false
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.resizeMode = .fast
    requestOptions.isNetworkAccessAllowed = false

    PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: 512, height: 512),
      contentMode: .aspectFit,
      options: requestOptions
    ) { image, info in
      let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
      if !isDegraded {
        resultImage = image?.cgImage
        semaphore.signal()
      }
    }

    // Wait with timeout
    let waitResult = semaphore.wait(timeout: .now() + 5.0)
    guard waitResult == .success, let cgImage = resultImage else {
      return nil
    }

    // Process image for payment slip
    return processImageForPaymentSlip(cgImage: cgImage, assetId: asset.localIdentifier)
  }

  private func processImageForPaymentSlip(cgImage: CGImage, assetId: String) -> [String: Any]? {
    return autoreleasepool {
      let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      var extractedText = ""
      var amount: Double?
      var date: String?

      let request = VNRecognizeTextRequest { [self] (request, error) in
        guard error == nil,
              let observations = request.results as? [VNRecognizedTextObservation] else { return }

        for observation in observations {
          guard let topCandidate = observation.topCandidates(1).first else { continue }
          let text = topCandidate.string
          extractedText += text + "\n"

          if amount == nil { amount = extractAmountFromText(text) }
          if date == nil { date = extractDateFromText(text) }
        }

        if amount == nil { amount = extractAmountFromText(extractedText) }
        if date == nil { date = extractDateFromText(extractedText) }
      }

      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["th-TH", "en-US"]
      request.usesLanguageCorrection = true

      do {
        try requestHandler.perform([request])

        if let foundAmount = amount, foundAmount > 0 {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
          dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

          return [
            "text": String(extractedText.prefix(10000)),
            "amount": foundAmount,
            "date": String((date ?? "").prefix(50)),
            "assetId": String(assetId.prefix(100)),
            "createdAt": dateFormatter.string(from: Date())
          ]
        }
      } catch {
        #if DEBUG
        print("❌ Vision error: \(error)")
        #endif
      }

      return nil
    }
  }

  // MARK: - Thread-Safe Callbacks to Flutter (from background thread)
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

  // MARK: - Cancellation
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

    // Process on background thread
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      var extractedText = ""
      var amount: Double?
      var date: String?

      let request = VNRecognizeTextRequest { [self] (request, error) in
        guard error == nil,
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

        DispatchQueue.main.async {
          result([
            "text": extractedText,
            "amount": amount ?? 0.0,
            "date": date ?? "",
            "imagePath": imagePath
          ])
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "VISION_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  // MARK: - Delete Image
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
    let patterns = [
      #"จำนวนเงิน\s*(\d{1,3}(?:,\d{3})*\.\d{2})"#,
      #"จำนวน:\s*(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      #"จำนวน\s+(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      #"(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      #"(?:จำนวน|amount|เงิน).*?(\d{1,3}(?:,\d{3})*\.\d{2})"#,
      #"\b(\d{1,3}(?:,\d{3})*\.\d{2})\b"#,
      #"\b([1-9]\d{1,2}\.\d{2})\b"#,
    ]

    for pattern in patterns {
      if let range = text.range(of: pattern, options: .regularExpression) {
        let matchedText = String(text[range])
        let numberPattern = #"(\d{1,3}(?:,\d{3})*\.\d{2})"#
        if let numberRange = matchedText.range(of: numberPattern, options: .regularExpression) {
          let amountString = String(matchedText[numberRange])
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
          if let amount = Double(amountString) {
            return amount
          }
        }
      }
    }
    return nil
  }

  private func extractDateFromText(_ text: String) -> String? {
    let patterns = [
      #"(\d{1,2})\s*มิ\.ย\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ม\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ก\.พ\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*มี\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*เม\.ย\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*พ\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ก\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ส\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ก\.ย\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ต\.ค\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*พ\.ย\.\s*(\d{2,4})"#,
      #"(\d{1,2})\s*ธ\.ค\.\s*(\d{2,4})"#,
      #"\d{1,2}/\d{1,2}/\d{4}"#,
      #"\d{1,2}-\d{1,2}-\d{4}"#,
      #"\d{4}/\d{1,2}/\d{1,2}"#,
      #"\d{4}-\d{1,2}-\d{1,2}"#
    ]

    for pattern in patterns {
      if let range = text.range(of: pattern, options: .regularExpression) {
        let dateString = String(text[range])
        if containsBuddhistYear(dateString) {
          return convertBuddhistToGregorian(dateString)
        }
        return dateString
      }
    }
    return nil
  }

  private func containsBuddhistYear(_ dateString: String) -> Bool {
    let pattern = #"25\d{2}|6[0-9]|7[0-9]"#
    return dateString.range(of: pattern, options: .regularExpression) != nil
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

    if let range = result.range(of: #"(25\d{2})"#, options: .regularExpression) {
      let year = String(result[range])
      if let y = Int(year) {
        result = result.replacingOccurrences(of: year, with: String(y - 543))
      }
    }

    if let range = result.range(of: #"\b([6-7]\d)\b"#, options: .regularExpression) {
      let shortYear = String(result[range])
      if let y = Int(shortYear) {
        result = result.replacingOccurrences(of: shortYear, with: String(2500 + y - 543))
      }
    }

    return result.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
  }
}
