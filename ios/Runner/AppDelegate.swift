import Flutter
import UIKit
import Vision
import Photos

// MARK: - Progress Tracking Actor
actor ScanProgressTracker {
  private var processed = 0
  private let total: Int
  private var slipsFound = 0
  
  init(total: Int) {
    self.total = total
  }
  
  func incrementProcessed() -> (current: Int, total: Int, percentage: Double) {
    processed = min(processed + 1, total)
    let percentage = min(Double(processed) / Double(max(total, 1)) * 100.0, 100.0)
    return (processed, total, percentage)
  }
  
  func incrementSlipsFound() -> Int {
    slipsFound += 1
    return slipsFound
  }
  
  func getProgress() -> (processed: Int, total: Int, slipsFound: Int, percentage: Double) {
    let percentage = min(Double(processed) / Double(max(total, 1)) * 100.0, 100.0)
    return (processed, total, slipsFound, percentage)
  }
  
  func reset() {
    processed = 0
    slipsFound = 0
  }
}

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
  private var scanningTask: Task<Void, Never>?
  private var progressTracker: ScanProgressTracker?
  private var progressUpdateTask: Task<Void, Never>?
  private var currentProgress: [String: Any] = [:]
  
  // MARK: - Application Lifecycle
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.slip_scanner/vision",
                                      binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "scanAllPhotos" {
        self?.scanAllPhotos(result: result)
      } else if call.method == "cancelScanning" {
        self?.cancelScanning()
        result(true)
      } else if call.method == "getProcessedPhotoIds" {
        self?.getProcessedPhotoIds(result: result)
      } else if call.method == "scanPaymentSlip" {
        guard let args = call.arguments as? Dictionary<String, Any>,
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                             message: "Image path is required",
                             details: nil))
          return
        }
        self?.scanPaymentSlip(imagePath: imagePath, result: result)
      } else if call.method == "deleteSlipImage" {
        guard let args = call.arguments as? Dictionary<String, Any>,
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                             message: "Image path is required",
                             details: nil))
          return
        }
        self?.deleteSlipImage(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Photo Scanning
  private func scanAllPhotos(result: @escaping FlutterResult) {
    // Cancel any existing scan
    cancelScanning()
    
    // Check photo library authorization
    let status = PHPhotoLibrary.authorizationStatus()
    
    guard status == .authorized || status == .limited else {
      if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization { newStatus in
          DispatchQueue.main.async {
            if newStatus == .authorized || newStatus == .limited {
              self.startAsyncScanning(result: result)
            } else {
              result(FlutterError(code: "PERMISSION_DENIED",
                                 message: "Photo library access denied",
                                 details: nil))
            }
          }
        }
      } else {
        result(FlutterError(code: "PERMISSION_DENIED",
                           message: "Photo library access denied",
                           details: nil))
      }
      return
    }
    
    startAsyncScanning(result: result)
  }
  
  private func startAsyncScanning(result: @escaping FlutterResult) {
    scanningTask = Task {
      await performScanAllPhotos(result: result)
    }
  }
  
  private func performScanAllPhotos(result: @escaping FlutterResult) async {
    // Fetch all photos
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    
    let assets = PHAsset.fetchAssets(with: fetchOptions)
    let totalCount = assets.count
    
    // Initialize progress tracker
    progressTracker = ScanProgressTracker(total: totalCount)
    
    // Initialize progress tracking
    currentProgress = [
      "total": totalCount,
      "processed": 0,
      "slipsFound": 0,
      "isComplete": false
    ]
    
    // Start progress updates
    startProgressUpdates()
    
    var scannedSlips: [[String: Any]] = []
    var allSlipsForFinalResult: [[String: Any]] = [] // Keep all slips for final result
    let chunkSize = 100 // Process and send results in chunks
    
    // Process photos with TaskGroup for concurrent execution
    await withTaskGroup(of: [String: Any]?.self) { group in
      var activeTaskCount = 0
      let maxConcurrentTasks = 8
      
      for i in 0..<totalCount {
        // Check for cancellation
        if Task.isCancelled {
          break
        }
        
        // Wait if we have too many active tasks and process completed ones
        while activeTaskCount >= maxConcurrentTasks {
          if let slipData = await group.next() {
            activeTaskCount -= 1
            if let data = slipData {
              scannedSlips.append(data)
              allSlipsForFinalResult.append(data) // Keep for final result
              
              // Send chunks when we have enough results
              if scannedSlips.count >= chunkSize {
                await sendResultsChunk(scannedSlips, isComplete: false, result: result)
                scannedSlips.removeAll(keepingCapacity: true)
              }
            }
          }
        }
        
        let asset = assets.object(at: i)
        activeTaskCount += 1
        
        group.addTask {
          return await self.processAssetAsync(asset)
        }
      }
      
      // Process remaining tasks
      for await slipData in group {
        if let data = slipData {
          scannedSlips.append(data)
          allSlipsForFinalResult.append(data) // Keep for final result
          
          // Send chunks for remaining results too
          if scannedSlips.count >= chunkSize {
            await sendResultsChunk(scannedSlips, isComplete: false, result: result)
            scannedSlips.removeAll(keepingCapacity: true)
          }
        }
      }
    }
    
    // Send final results with all slips (remaining chunk + all slips as backup)
    await sendFinalResults(scannedSlips, allSlips: allSlipsForFinalResult, result: result)
  }
  
  private func processAssetAsync(_ asset: PHAsset) async -> [String: Any]? {
    do {
      // Load image asynchronously
      let image = try await loadImageAsync(from: asset)
      
      // Process for payment slip
      if let slipData = processImageForPaymentSlip(cgImage: image, assetId: asset.localIdentifier) {
        // Update progress
        let (_, _, _) = await progressTracker?.incrementProcessed() ?? (0, 0, 0.0)
        let _ = await progressTracker?.incrementSlipsFound()
        return slipData
      } else {
        // Still count as processed even if not a slip
        let _ = await progressTracker?.incrementProcessed()
        return nil
      }
    } catch {
      print("❌ Error processing asset: \(error)")
      let _ = await progressTracker?.incrementProcessed()
      return nil
    }
  }
  
  private func loadImageAsync(from asset: PHAsset) async throws -> CGImage {
    return try await withCheckedThrowingContinuation { continuation in
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
        // Check if this is the final callback
        let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
        guard !isDegraded else { return }
        
        if let image = image, let cgImage = image.cgImage {
          continuation.resume(returning: cgImage)
        } else {
          continuation.resume(throwing: NSError(domain: "ImageLoadError", code: 1, userInfo: nil))
        }
      }
    }
  }
  
  // MARK: - Progress Management
  private func startProgressUpdates() {
    progressUpdateTask?.cancel()
    progressUpdateTask = Task {
      // Update progress every 0.5 seconds
      while !Task.isCancelled {
        if let tracker = progressTracker {
          let progress = await tracker.getProgress()
          
          await MainActor.run {
            currentProgress = [
              "total": progress.total,
              "processed": progress.processed,
              "slipsFound": progress.slipsFound,
              "isComplete": false
            ]
            sendProgressUpdate()
          }
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
      }
    }
  }
  
  private func sendProgressUpdate() {
    // Ensure progress updates are sent on the main thread
    DispatchQueue.main.async {
      guard let controller = self.window?.rootViewController as? FlutterViewController else { 
        print("❌ DEBUG: Could not get FlutterViewController for progress update")
        return 
      }
      
      let channel = FlutterMethodChannel(name: "com.example.slip_scanner/progress",
                                        binaryMessenger: controller.binaryMessenger)
      
      print("📊 DEBUG: Sending progress update: \(self.currentProgress)")
      channel.invokeMethod("onProgress", arguments: self.currentProgress)
    }
  }
  
  // MARK: - Result Management
  private func sendResultsChunk(_ slips: [[String: Any]], isComplete: Bool, result: @escaping FlutterResult) async {
    // Send partial results via progress channel to prevent memory buildup
    await MainActor.run {
      guard let controller = self.window?.rootViewController as? FlutterViewController else { 
        print("❌ Could not get FlutterViewController for chunk update")
        return 
      }
      
      let channel = FlutterMethodChannel(name: "com.example.slip_scanner/progress",
                                        binaryMessenger: controller.binaryMessenger)
      
      let chunkData: [String: Any] = [
        "type": "partial_results",
        "slips": slips,
        "isComplete": isComplete
      ]
      
      print("📦 Sending chunk with \(slips.count) slips, isComplete: \(isComplete)")
      channel.invokeMethod("onPartialResults", arguments: chunkData)
    }
  }
  
  private func sendFinalResults(_ remainingSlips: [[String: Any]], allSlips: [[String: Any]], result: @escaping FlutterResult) async {
    progressUpdateTask?.cancel()
    
    // Send any remaining slips as a final chunk
    if !remainingSlips.isEmpty {
      await sendResultsChunk(remainingSlips, isComplete: false, result: result)
    }
    
    guard let tracker = progressTracker else { return }
    let finalProgress = await tracker.getProgress()
    
    await MainActor.run {
      currentProgress = [
        "total": finalProgress.total,
        "processed": finalProgress.processed,
        "slipsFound": finalProgress.slipsFound,
        "isComplete": true
      ]
      sendProgressUpdate()
      
      if Task.isCancelled {
        result(FlutterError(code: "CANCELLED",
                           message: "Scanning was cancelled",
                           details: nil))
      } else {
        // Return summary with ALL slips as backup (Flutter prioritizes chunked results but falls back to this)
        result([
          "total": finalProgress.total,
          "processed": finalProgress.processed,
          "slipsFound": finalProgress.slipsFound,
          "slips": allSlips // Include ALL slips as fallback for compatibility
        ])
      }
    }
  }
  
  // MARK: - Cancellation
  private func cancelScanning() {
    scanningTask?.cancel()
    progressUpdateTask?.cancel()
    scanningTask = nil
    progressUpdateTask = nil
  }
  
  // MARK: - Other Methods
  private func getProcessedPhotoIds(result: @escaping FlutterResult) {
    // Return empty array since we don't track processed photo IDs in this implementation
    // If persistence is needed, this would query the SQLite database for existing assetIds
    result([])
  }
  
  // MARK: - Image Processing
  private func processImageForPaymentSlip(cgImage: CGImage, assetId: String) -> [String: Any]? {
    print("🔍 DEBUG: Processing image for payment slip with assetId: \(assetId)")
    
    // Use autoreleasepool for Vision Framework operations
    return autoreleasepool {
      let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      var extractedText = ""
      var amount: Double?
      var date: String?
      
      let semaphore = DispatchSemaphore(value: 0)
      
      let request = VNRecognizeTextRequest { (request, error) in
        defer { semaphore.signal() }
        
        guard error == nil,
              let observations = request.results as? [VNRecognizedTextObservation] else {
          print("❌ DEBUG: OCR error or no observations")
          return
        }
        
        print("🔍 DEBUG: Processing \(observations.count) text observations")
        
        // First pass: collect all text and try individual lines
        for (index, observation) in observations.enumerated() {
          guard let topCandidate = observation.topCandidates(1).first else { continue }
          let text = topCandidate.string
          extractedText += text + "\n"
          
          print("🔍 DEBUG: Observation \(index + 1): '\(text)'")
          
          // Try to extract amount from individual line
          if amount == nil {
            amount = self.extractAmountFromText(text)
            if amount != nil {
              print("✅ DEBUG: Found amount \(amount!) in observation \(index + 1)")
            }
          }
          
          // Try to extract date from individual line
          if date == nil {
            date = self.extractDateFromText(text)
            if date != nil {
              print("✅ DEBUG: Found date '\(date!)' in observation \(index + 1)")
            }
          }
        }
        
        // Second pass: try full combined text if amount not found
        if amount == nil {
          print("🔍 DEBUG: Trying amount extraction on full combined text")
          amount = self.extractAmountFromText(extractedText)
          if amount != nil {
            print("✅ DEBUG: Found amount \(amount!) in combined text")
          }
        }
        
        // Second pass: try full combined text if date not found
        if date == nil {
          print("📅 DEBUG: Trying date extraction on full combined text")
          date = self.extractDateFromText(extractedText)
          if date != nil {
            print("✅ DEBUG: Found date '\(date!)' in combined text")
          }
        }
        
        print("🔍 DEBUG: Final results - Amount: \(amount ?? 0), Date: '\(date ?? "none")'")
        print("🔍 DEBUG: Full extracted text: '\(extractedText)'")
      }
      
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["th-TH", "en-US"]
      request.usesLanguageCorrection = true
      
      do {
        try requestHandler.perform([request])
        semaphore.wait()
        
        // Only return if we found an amount (indicating this might be a payment slip)
        if let foundAmount = amount, foundAmount > 0 {
          // Create proper date string to avoid Flutter codec issues
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
          dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
          let createdAtString = dateFormatter.string(from: Date())
          
          // Validate all values before returning to prevent codec errors
          let validatedData: [String: Any] = [
            "text": String(extractedText.prefix(10000)), // Limit text length
            "amount": max(0.0, foundAmount), // Ensure positive amount
            "date": String((date ?? "").prefix(50)), // Limit date string
            "assetId": String(assetId.prefix(100)), // Limit asset ID
            "createdAt": createdAtString
          ]
          
          return validatedData
        }
      } catch {
        // Handle processing errors gracefully
        print("❌ DEBUG: Vision processing error: \(error)")
        return nil
      }
      
      return nil
    } // autoreleasepool
  }
  
  private func scanPaymentSlip(imagePath: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage else {
      result(FlutterError(code: "IMAGE_ERROR",
                         message: "Could not load image from path",
                         details: nil))
      return
    }
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest { (request, error) in
      if let error = error {
        result(FlutterError(code: "VISION_ERROR",
                           message: error.localizedDescription,
                           details: nil))
        return
      }
      
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        result(FlutterError(code: "VISION_ERROR",
                           message: "Could not get text observations",
                           details: nil))
        return
      }
      
      var extractedText = ""
      var amount: Double?
      var date: String?
      
      // First pass: collect all text and try individual lines
      for observation in observations {
        guard let topCandidate = observation.topCandidates(1).first else { continue }
        let text = topCandidate.string
        extractedText += text + "\n"
        
        // Extract amount using improved Thai banking patterns
        if amount == nil {
          amount = self.extractAmountFromText(text)
        }
        
        // Extract date using improved Thai date patterns
        if date == nil {
          date = self.extractDateFromText(text)
        }
      }
      
      // Second pass: try full combined text if not found
      if amount == nil {
        amount = self.extractAmountFromText(extractedText)
      }
      
      if date == nil {
        date = self.extractDateFromText(extractedText)
      }
      
      let responseData: [String: Any] = [
        "text": extractedText,
        "amount": amount ?? 0.0,
        "date": date ?? "",
        "imagePath": imagePath
      ]
      
      result(responseData)
    }
    
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["th-TH", "en-US"]
    request.usesLanguageCorrection = true
    
    do {
      try requestHandler.perform([request])
    } catch {
      result(FlutterError(code: "VISION_ERROR",
                         message: error.localizedDescription,
                         details: nil))
    }
  }
  
  private func deleteSlipImage(imagePath: String, result: @escaping FlutterResult) {
    // Check if we're trying to delete from photo library
    if imagePath.contains("asset-library://") || imagePath.contains("ph://") {
      // For photo library assets, we can't delete them directly
      // Just return success as the app won't store references to them
      result(true)
      return
    }
    
    // For files in app's documents directory
    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: imagePath) {
        try fileManager.removeItem(atPath: imagePath)
        result(true)
      } else {
        result(true) // File doesn't exist, consider it success
      }
    } catch {
      result(FlutterError(code: "DELETE_ERROR",
                         message: error.localizedDescription,
                         details: nil))
    }
  }
  
  // MARK: - Text Extraction
  private func extractAmountFromText(_ text: String) -> Double? {
    // Debug logging
    print("🔍 DEBUG: Extracting amount from text: '\(text)'")
    
    // Thai banking patterns - PRIORITIZED ORDER (most specific first)
    let thaiAmountPatterns = [
      // 1. SCB format: "จำนวนเงิน 1,234.56" (with comma separators)
      #"จำนวนเงิน\s*(\d{1,3}(?:,\d{3})*\.\d{2})"#,
      
      // 2. KBank format: "จำนวน: 1,234.56 บาท" (with comma separators)
      #"จำนวน:\s*(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      
      // 3. General format: "จำนวน 1,234.56 บาท" (with comma separators)
      #"จำนวน\s+(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      
      // 4. Simple format: "1,234.56 บาท" (with comma separators)
      #"(\d{1,3}(?:,\d{3})*\.\d{2})\s*บาท"#,
      
      // 5. Any Thai banking context (fallback with comma separators)
      #"(?:จำนวน|amount|เงิน).*?(\d{1,3}(?:,\d{3})*\.\d{2})"#,
      
      // 6. Decimal numbers with proper comma formatting
      #"\b(\d{1,3}(?:,\d{3})*\.\d{2})\b"#,
      
      // 7. Simple decimal numbers (no commas, under 1000)
      #"\b([1-9]\d{1,2}\.\d{2})\b"#,
      
      // 8. Specific patterns for common amounts
      #"\b(70\.00)\b"#,
      #"\b(520\.00)\b"#,
      #"\b(1,000\.00)\b"#,
      #"\b(10,000\.00)\b"#,
      #"\b(100,000\.00)\b"#,
      #"\b(1,000,000\.00)\b"#,
    ]
    
    for (index, pattern) in thaiAmountPatterns.enumerated() {
      print("🔍 DEBUG: Trying pattern \(index + 1): \(pattern)")
      
      if let range = text.range(of: pattern, options: .regularExpression) {
        let matchedText = String(text[range])
        print("🔍 DEBUG: Pattern \(index + 1) matched: '\(matchedText)'")
        
        // Extract just the number part (supports comma separators)
        let numberPattern = #"(\d{1,3}(?:,\d{3})*\.\d{2})"#
        if let numberRange = matchedText.range(of: numberPattern, options: .regularExpression) {
          let amountString = String(matchedText[numberRange])
            .replacingOccurrences(of: ",", with: "")  // Remove commas: "1,000.00" → "1000.00"
            .replacingOccurrences(of: " ", with: "")  // Remove spaces
          
          print("🔍 DEBUG: Extracted amount string: '\(amountString)' (after comma removal)")
          
          if let amount = Double(amountString) {
            print("✅ DEBUG: Successfully extracted amount: \(amount)")
            return amount
          } else {
            print("❌ DEBUG: Failed to convert '\(amountString)' to Double")
          }
        } else {
          print("❌ DEBUG: No number found in matched text: '\(matchedText)'")
        }
      }
    }
    
    print("❌ DEBUG: No amount found in text")
    return nil
  }
  
  private func extractDateFromText(_ text: String) -> String? {
    // Debug logging
    print("📅 DEBUG: Extracting date from text: '\(text)'")
    
    // Thai date patterns with Buddhist calendar
    let thaiDatePatterns = [
      #"(\d{1,2})\s*มิ\.ย\.\s*(\d{2,4})"#, // June
      #"(\d{1,2})\s*ม\.ค\.\s*(\d{2,4})"#, // January
      #"(\d{1,2})\s*ก\.พ\.\s*(\d{2,4})"#, // February
      #"(\d{1,2})\s*มี\.ค\.\s*(\d{2,4})"#, // March
      #"(\d{1,2})\s*เม\.ย\.\s*(\d{2,4})"#, // April
      #"(\d{1,2})\s*พ\.ค\.\s*(\d{2,4})"#, // May
      #"(\d{1,2})\s*ก\.ค\.\s*(\d{2,4})"#, // July
      #"(\d{1,2})\s*ส\.ค\.\s*(\d{2,4})"#, // August
      #"(\d{1,2})\s*ก\.ย\.\s*(\d{2,4})"#, // September
      #"(\d{1,2})\s*ต\.ค\.\s*(\d{2,4})"#, // October
      #"(\d{1,2})\s*พ\.ย\.\s*(\d{2,4})"#, // November
      #"(\d{1,2})\s*ธ\.ค\.\s*(\d{2,4})"#, // December
      // International formats
      #"\d{1,2}/\d{1,2}/\d{4}"#,
      #"\d{1,2}-\d{1,2}-\d{4}"#,
      #"\d{4}/\d{1,2}/\d{1,2}"#,
      #"\d{4}-\d{1,2}-\d{1,2}"#
    ]
    
    for (index, pattern) in thaiDatePatterns.enumerated() {
      if let range = text.range(of: pattern, options: .regularExpression) {
        let dateString = String(text[range])
        print("✅ DEBUG: Found date with pattern \(index + 1): '\(dateString)'")
        
        // Convert Buddhist calendar to Gregorian if needed
        if containsBuddhistYear(dateString) {
          let convertedDate = convertBuddhistToGregorian(dateString)
          print("📅 DEBUG: Converted Buddhist date '\(dateString)' to '\(convertedDate)'")
          return convertedDate
        }
        
        print("📅 DEBUG: Using date as-is: '\(dateString)'")
        return dateString
      }
    }
    
    print("❌ DEBUG: No date found in text")
    return nil
  }
  
  private func containsBuddhistYear(_ dateString: String) -> Bool {
    // Check for Buddhist Era years (typically 2500+ or 2-digit years in Thai context)
    let buddhistYearPattern = #"25\d{2}|6[0-9]|7[0-9]"#
    return dateString.range(of: buddhistYearPattern, options: .regularExpression) != nil
  }
  
  private func convertBuddhistToGregorian(_ dateString: String) -> String {
    let monthMap = [
      "ม.ค.": "01", "ก.พ.": "02", "มี.ค.": "03", "เม.ย.": "04",
      "พ.ค.": "05", "มิ.ย.": "06", "ก.ค.": "07", "ส.ค.": "08",
      "ก.ย.": "09", "ต.ค.": "10", "พ.ย.": "11", "ธ.ค.": "12"
    ]
    
    var result = dateString
    
    // Convert Thai month abbreviations to numbers
    for (thaiMonth, monthNum) in monthMap {
      result = result.replacingOccurrences(of: thaiMonth, with: "/\(monthNum)/")
    }
    
    // Convert Buddhist year to Gregorian (subtract 543 years)
    // Handle 4-digit Buddhist years (2500-2600 range)
    let fourDigitBuddhistPattern = #"(25\d{2})"#
    if let range = result.range(of: fourDigitBuddhistPattern, options: .regularExpression) {
      let buddhistYear = String(result[range])
      if let year = Int(buddhistYear) {
        let gregorianYear = year - 543
        result = result.replacingOccurrences(of: buddhistYear, with: String(gregorianYear))
      }
    }
    
    // Handle 2-digit Buddhist years (60-79 representing 2560-2579 BE)
    let twoDigitBuddhistPattern = #"\b([6-7]\d)\b"#
    if let range = result.range(of: twoDigitBuddhistPattern, options: .regularExpression) {
      let shortYear = String(result[range])
      if let year = Int(shortYear) {
        let fullBuddhistYear = 2500 + year
        let gregorianYear = fullBuddhistYear - 543
        result = result.replacingOccurrences(of: shortYear, with: String(gregorianYear))
      }
    }
    
    // Clean up extra spaces and format
    result = result.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    
    return result
  }
}