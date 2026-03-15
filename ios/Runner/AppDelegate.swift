import Flutter
import UIKit

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
    private var photoScanner: PhotoScanner?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        let progressChannel = FlutterMethodChannel(
            name: "com.avers.app/progress",
            binaryMessenger: controller.binaryMessenger
        )
        let visionChannel = FlutterMethodChannel(
            name: "com.avers.app/vision",
            binaryMessenger: controller.binaryMessenger
        )

        photoScanner = PhotoScanner(progressChannel: progressChannel)

        visionChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "scanAllPhotos":
                var processedIds: Set<String> = []
                if let args = call.arguments as? [String: Any],
                   let ids = args["processedAssetIds"] as? [String] {
                    processedIds = Set(ids)
                }
                self?.photoScanner?.scanAllPhotos(processedAssetIds: processedIds, result: result)
            case "cancelScanning":
                self?.photoScanner?.cancelScanning()
                result(true)
            case "getProcessedPhotoIds":
                result([])
            case "scanPaymentSlip":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path required", details: nil))
                    return
                }
                self?.photoScanner?.scanPaymentSlip(imagePath: imagePath, result: result)
            case "deleteSlipImage":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path required", details: nil))
                    return
                }
                self?.photoScanner?.deleteSlipImage(imagePath: imagePath, result: result)
            case "loadImageFromAsset":
                guard let args = call.arguments as? [String: Any],
                      let assetId = args["assetId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Asset ID required", details: nil))
                    return
                }
                self?.photoScanner?.loadImageFromAsset(assetId: assetId, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
