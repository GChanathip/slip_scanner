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
          }
        }
        
        // Update progress and add found slips
        slipsFound += batchSlips.count
        scannedSlips.append(contentsOf: batchSlips)
        
        self.currentProgress["processed"] = processedCount
        self.currentProgress["slipsFound"] = slipsFound
        
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
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    
    let channel = FlutterMethodChannel(name: "com.example.slip_scanner/progress",
                                      binaryMessenger: controller.binaryMessenger)
    channel.invokeMethod("onProgress", arguments: currentProgress)
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
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    var extractedText = ""
    var amount: Double?
    var date: String?
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let request = VNRecognizeTextRequest { (request, error) in
      defer { semaphore.signal() }
      
      guard error == nil,
            let observations = request.results as? [VNRecognizedTextObservation] else {
        return
      }
      
      for observation in observations {
        guard let topCandidate = observation.topCandidates(1).first else { continue }
        let text = topCandidate.string
        extractedText += text + "\n"
        
        // Extract amount (look for patterns like $123.45, 123.45, etc.)
        if amount == nil {
          let amountPattern = #"[$€¥£]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#
          if let range = text.range(of: amountPattern, options: .regularExpression) {
            let amountString = String(text[range])
              .replacingOccurrences(of: "$", with: "")
              .replacingOccurrences(of: "€", with: "")
              .replacingOccurrences(of: "¥", with: "")
              .replacingOccurrences(of: "£", with: "")
              .replacingOccurrences(of: ",", with: "")
              .replacingOccurrences(of: " ", with: "")
            amount = Double(amountString)
          }
        }
        
        // Extract date (look for common date patterns)
        if date == nil {
          let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{4}"#,
            #"\d{1,2}-\d{1,2}-\d{4}"#,
            #"\d{4}/\d{1,2}/\d{1,2}"#,
            #"\d{4}-\d{1,2}-\d{1,2}"#
          ]
          
          for pattern in datePatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
              date = String(text[range])
              break
            }
          }
        }
      }
    }
    
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US"]
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
      
      for observation in observations {
        guard let topCandidate = observation.topCandidates(1).first else { continue }
        let text = topCandidate.string
        extractedText += text + "\n"
        
        // Extract amount (look for patterns like $123.45, 123.45, etc.)
        if amount == nil {
          let amountPattern = #"[$€¥£]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#
          if let range = text.range(of: amountPattern, options: .regularExpression) {
            let amountString = String(text[range])
              .replacingOccurrences(of: "$", with: "")
              .replacingOccurrences(of: "€", with: "")
              .replacingOccurrences(of: "¥", with: "")
              .replacingOccurrences(of: "£", with: "")
              .replacingOccurrences(of: ",", with: "")
              .replacingOccurrences(of: " ", with: "")
            amount = Double(amountString)
          }
        }
        
        // Extract date (look for common date patterns)
        if date == nil {
          let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{4}"#,
            #"\d{1,2}-\d{1,2}-\d{4}"#,
            #"\d{4}/\d{1,2}/\d{1,2}"#,
            #"\d{4}-\d{1,2}-\d{1,2}"#
          ]
          
          for pattern in datePatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
              date = String(text[range])
              break
            }
          }
        }
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
    request.recognitionLanguages = ["en-US"]
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
}