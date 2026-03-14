import Flutter
import Photos

// MARK: - Photo Scanner
// Manages bulk photo library scanning, single-image scanning, and asset operations.
class PhotoScanner {

    private weak var progressChannel: FlutterMethodChannel?
    private let ocrService = OCRService()

    private let stateLock = NSLock()
    private var _activeScanId: UUID?

    /// Creates a new scan token and returns it. Implicitly invalidates any previous scan.
    private func startNewScan() -> UUID {
        stateLock.lock(); defer { stateLock.unlock() }
        let id = UUID()
        _activeScanId = id
        return id
    }

    /// Returns true if the given scan token is no longer the active scan.
    private func isScanCancelled(_ scanId: UUID) -> Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _activeScanId != scanId
    }

    private lazy var maxConcurrentOperations: Int = {
        min(ProcessInfo.processInfo.activeProcessorCount, 6)
    }()

    init(progressChannel: FlutterMethodChannel?) {
        self.progressChannel = progressChannel
    }

    // MARK: - Cancellation

    func cancelScanning() {
        stateLock.lock(); defer { stateLock.unlock() }
        _activeScanId = nil
    }

    // MARK: - Bulk Scanning

    func scanAllPhotos(processedAssetIds: Set<String>, result: @escaping FlutterResult) {
        // Generate a fresh token; this implicitly invalidates any in-flight scan.
        let scanId = startNewScan()

        let status = PHPhotoLibrary.authorizationStatus()

        guard status == .authorized || status == .limited else {
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            self?.startBackgroundScanning(scanId: scanId, processedAssetIds: processedAssetIds, result: result)
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

        startBackgroundScanning(scanId: scanId, processedAssetIds: processedAssetIds, result: result)
    }

    private func startBackgroundScanning(scanId: UUID, processedAssetIds: Set<String>, result: @escaping FlutterResult) {
        // Return immediately - don't block platform/UI thread
        result(["status": "started", "message": "Scanning started"])

        // Run on background thread (NOT Task{} which inherits MainActor)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performStreamingScanning(scanId: scanId, processedAssetIds: processedAssetIds)
        }
    }

    // MARK: - Streaming Scan (real-time progress, NO chunking, NO throttling)
    private func performStreamingScanning(scanId: UUID, processedAssetIds: Set<String>) {
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
        var iCloudSkippedCount = 0
        // Throttle state (guarded by counterLock)
        var lastProgressSentCount = 0
        var lastProgressSentNanos: UInt64 = DispatchTime.now().uptimeNanoseconds

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
            guard !isScanCancelled(scanId) else { break }

            let asset = assets.object(at: i)

            // Skip assets already in the database — no OCR needed
            if processedAssetIds.contains(asset.localIdentifier) {
                counterLock.lock()
                processedCount += 1
                let currentProcessed = processedCount
                let currentSlipsFound = slipsFoundCount
                let nowNanos = DispatchTime.now().uptimeNanoseconds
                let elapsedMs = Double(nowNanos - lastProgressSentNanos) / 1_000_000
                let shouldSend = (currentProcessed - lastProgressSentCount) >= 50 || elapsedMs >= 200
                if shouldSend {
                    lastProgressSentCount = currentProcessed
                    lastProgressSentNanos = nowNanos
                }
                counterLock.unlock()
                if shouldSend {
                    sendProgressFromBackground(
                        total: totalCount,
                        processed: currentProcessed,
                        slipsFound: currentSlipsFound,
                        isComplete: false
                    )
                }
                continue
            }

            completionGroup.enter()

            operationQueue.addOperation { [weak self] in
                defer { completionGroup.leave() }
                guard let self = self, !self.isScanCancelled(scanId) else { return }

                // Process single image with autoreleasepool
                autoreleasepool {
                    let assetResult = self.processAsset(asset)

                    // Update counters
                    counterLock.lock()
                    processedCount += 1
                    let currentProcessed = processedCount
                    switch assetResult {
                    case .processed: slipsFoundCount += 1
                    case .iCloudOnly: iCloudSkippedCount += 1
                    case .notASlip: break
                    }
                    let currentSlipsFound = slipsFoundCount
                    let currentICloudSkipped = iCloudSkippedCount
                    let nowNanos = DispatchTime.now().uptimeNanoseconds
                    let elapsedMs = Double(nowNanos - lastProgressSentNanos) / 1_000_000
                    let shouldSendProgress = (currentProcessed - lastProgressSentCount) >= 50 || elapsedMs >= 200
                    if shouldSendProgress {
                        lastProgressSentCount = currentProcessed
                        lastProgressSentNanos = nowNanos
                    }
                    counterLock.unlock()

                    // Accumulate slip if found
                    if case .processed(let foundSlip) = assetResult {
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

                    // Throttled progress: every 50 images or every 200ms
                    if shouldSendProgress {
                        self.sendProgressFromBackground(
                            total: totalCount,
                            processed: currentProcessed,
                            slipsFound: currentSlipsFound,
                            iCloudSkipped: currentICloudSkipped,
                            isComplete: false
                        )
                    }
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
        let finalICloudSkipped = iCloudSkippedCount
        counterLock.unlock()

        sendProgressFromBackground(
            total: totalCount,
            processed: finalProcessed,
            slipsFound: finalSlipsFound,
            iCloudSkipped: finalICloudSkipped,
            isComplete: true
        )
    }

    // MARK: - Image Processing

    private enum AssetResult {
        case processed([String: Any])
        case notASlip
        case iCloudOnly
    }

    private func processAsset(_ asset: PHAsset) -> AssetResult {
        let (cgImage, isICloudOnly) = loadImageSync(from: asset)
        guard let cgImage = cgImage else {
            return isICloudOnly ? .iCloudOnly : .notASlip
        }
        if let slip = ocrService.processImageForPaymentSlip(cgImage: cgImage, assetId: asset.localIdentifier) {
            return .processed(slip)
        }
        return .notASlip
    }

    private func loadImageSync(from asset: PHAsset) -> (image: CGImage?, isICloudOnly: Bool) {
        var resultImage: CGImage?
        var isICloudOnly = false

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
        ) { image, info in
            resultImage = image?.cgImage
            if image == nil {
                isICloudOnly = info?[PHImageResultIsInCloudKey] as? Bool == true
            }
        }

        return (resultImage, isICloudOnly)
    }

    // MARK: - Flutter Progress Callbacks

    private func sendProgressFromBackground(total: Int, processed: Int, slipsFound: Int, iCloudSkipped: Int = 0, isComplete: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.progressChannel?.invokeMethod("onProgress", arguments: [
                "total": total,
                "processed": processed,
                "slipsFound": slipsFound,
                "iCloudSkipped": iCloudSkipped,
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

    // MARK: - Single Image Scanning

    func scanPaymentSlip(imagePath: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
            result(FlutterError(code: "IMAGE_ERROR", message: "Could not load image", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let (text, amount, date) = self.ocrService.recognizeText(from: cgImage)
            var slipResult = self.ocrService.buildSlipResult(
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

    // MARK: - Asset Operations

    func deleteSlipImage(imagePath: String, result: @escaping FlutterResult) {
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

    func loadImageFromAsset(assetId: String, result: @escaping FlutterResult) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = fetchResult.firstObject else {
            result(FlutterError(code: "NOT_FOUND", message: "Asset not found", details: nil))
            return
        }

        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = false

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: .aspectFit,
            options: requestOptions
        ) { image, _ in
            DispatchQueue.main.async {
                if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(FlutterError(code: "IMAGE_ERROR", message: "Could not load image data", details: nil))
                }
            }
        }
    }
}
