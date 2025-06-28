import Flutter
import UIKit
import Vision
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var scanningCancelled = false
  private var progressTimer: Timer?
  private var currentProgress: [String: Any] = [:]
  
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
        self?.cancelScanning(result: result)
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
  
  private func scanAllPhotos(result: @escaping FlutterResult) {
    // Check photo library authorization
    let status = PHPhotoLibrary.authorizationStatus()
    
    guard status == .authorized || status == .limited else {
      if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization { newStatus in
          DispatchQueue.main.async {
            if newStatus == .authorized || newStatus == .limited {
              self.performScanAllPhotos(result: result)
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
    
    performScanAllPhotos(result: result)
  }
  
  private func performScanAllPhotos(result: @escaping FlutterResult) {
    scanningCancelled = false
    
    DispatchQueue.global(qos: .userInitiated).async {
      // Fetch all photos
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
      
      let assets = PHAsset.fetchAssets(with: fetchOptions)
      let totalCount = assets.count
      
      var processedCount = 0
      var slipsFound = 0
      var scannedSlips: [[String: Any]] = []
      
      // Initialize progress tracking
      self.currentProgress = [
        "total": totalCount,
        "processed": 0,
        "slipsFound": 0,
        "isComplete": false
      ]
      
      // Start progress timer for batched UI updates
      DispatchQueue.main.async {
        self.startProgressTimer()
      }
      
      let imageManager = PHImageManager.default()
      let requestOptions = PHImageRequestOptions()
      requestOptions.isSynchronous = true
      requestOptions.deliveryMode = .highQualityFormat
      
      // Process photos in batches
      let batchSize = 20
      for batchStart in stride(from: 0, to: totalCount, by: batchSize) {
        if self.scanningCancelled {
          break
        }
        
        let batchEnd = min(batchStart + batchSize, totalCount)
        var batchSlips: [[String: Any]] = []
        
        for i in batchStart..<batchEnd {
          if self.scanningCancelled {
            break
          }
          
          let asset = assets.object(at: i)
          
          imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: .aspectFit,
            options: requestOptions
          ) { image, _ in
            if let image = image,
               let cgImage = image.cgImage {
              
              if let slipData = self.processImageForPaymentSlip(cgImage: cgImage, assetId: asset.localIdentifier) {
                batchSlips.append(slipData)
              }
            }
            
            processedCount += 1
            
            // Update progress immediately after each photo
            self.currentProgress["processed"] = processedCount
            self.sendProgressUpdate()
            
            print("📊 DEBUG: Processed photo \(processedCount)/\(totalCount), batch slips: \(batchSlips.count)")
          }
        }
        
        // Update progress and add found slips
        slipsFound += batchSlips.count
        scannedSlips.append(contentsOf: batchSlips)
        
        self.currentProgress["processed"] = processedCount
        self.currentProgress["slipsFound"] = slipsFound
        self.sendProgressUpdate()
        
        // Small delay to prevent overwhelming the system
        usleep(50000) // 50ms
      }
      
      // Complete scanning
      self.currentProgress["processed"] = processedCount
      self.currentProgress["slipsFound"] = slipsFound
      self.currentProgress["isComplete"] = true
      
      DispatchQueue.main.async {
        self.stopProgressTimer()
        
        if self.scanningCancelled {
          result(FlutterError(code: "CANCELLED",
                             message: "Scanning was cancelled",
                             details: nil))
        } else {
          result([
            "total": totalCount,
            "processed": processedCount,
            "slipsFound": slipsFound,
            "slips": scannedSlips
          ])
        }
      }
    }
  }
  
  private func startProgressTimer() {
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      self.sendProgressUpdate()
    }
  }
  
  private func stopProgressTimer() {
    progressTimer?.invalidate()
    progressTimer = nil
    // Send final progress update
    sendProgressUpdate()
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
  
  private func cancelScanning(result: @escaping FlutterResult) {
    scanningCancelled = true
    stopProgressTimer()
    result(true)
  }
  
  private func getProcessedPhotoIds(result: @escaping FlutterResult) {
    // This would typically come from your database
    // For now, return empty array
    result([])
  }
  
  private func processImageForPaymentSlip(cgImage: CGImage, assetId: String) -> [String: Any]? {
    print("🔍 DEBUG: Processing image for payment slip with assetId: \(assetId)")
    
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
        return [
          "text": extractedText,
          "amount": foundAmount,
          "date": date ?? "",
          "assetId": assetId,
          "createdAt": ISO8601DateFormatter().string(from: Date())
        ]
      }
    } catch {
      // Ignore processing errors for individual images
    }
    
    return nil
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