import Cocoa
import FlutterMacOS
import Vision

/// Simplified OCR entry point for macOS.
/// Takes image data or file path (from LINE CDN), runs Vision OCR + regex extraction.
/// No PHPhotoLibrary dependency — images come from LINE, not the photo library.
class SlipProcessor {
    private let ocrService = OCRService()

    /// Process raw image data bytes (e.g., downloaded from LINE CDN).
    func processImageData(_ data: Data) -> [String: Any]? {
        guard let nsImage = NSImage(data: data),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        return ocrService.processImageForPaymentSlip(
            cgImage: cgImage,
            assetId: "line_\(UUID().uuidString)"
        )
    }

    /// Process a single image file at the given path.
    func processImageFile(at path: String) -> [String: Any]? {
        guard let nsImage = NSImage(contentsOfFile: path),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        return ocrService.processImageForPaymentSlip(
            cgImage: cgImage,
            assetId: "line_\(UUID().uuidString)"
        )
    }
}
