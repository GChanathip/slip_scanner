import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var slipProcessor: SlipProcessor?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            return
        }

        let visionChannel = FlutterMethodChannel(
            name: "com.avers.app/vision",
            binaryMessenger: controller.engine.binaryMessenger
        )

        slipProcessor = SlipProcessor()

        visionChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "processImageData":
                guard let args = call.arguments as? [String: Any],
                      let imageData = args["imageData"] as? FlutterStandardTypedData else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "imageData required", details: nil))
                    return
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    autoreleasepool {
                        guard let processor = self?.slipProcessor else {
                            DispatchQueue.main.async {
                                result(FlutterError(code: "UNAVAILABLE", message: "Processor not available", details: nil))
                            }
                            return
                        }
                        let slipResult = processor.processImageData(imageData.data)
                        DispatchQueue.main.async {
                            result(slipResult)
                        }
                    }
                }

            case "scanPaymentSlip":
                guard let args = call.arguments as? [String: Any],
                      let imagePath = args["imagePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "imagePath required", details: nil))
                    return
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    autoreleasepool {
                        guard let processor = self?.slipProcessor else {
                            DispatchQueue.main.async {
                                result(FlutterError(code: "UNAVAILABLE", message: "Processor not available", details: nil))
                            }
                            return
                        }
                        let slipResult = processor.processImageFile(at: imagePath)
                        DispatchQueue.main.async {
                            result(slipResult)
                        }
                    }
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
