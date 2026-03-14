import XCTest
import UIKit
@testable import Runner

/// Image-based end-to-end OCR tests.
/// These test the full pipeline: load image -> Vision OCR -> regex extraction -> structured dictionary.
/// Requires iOS Simulator (Vision framework). Slower than text-based tests.
///
/// ## Adding a new image test:
/// 1. Add the slip image to `Fixtures/Images/` directory
/// 2. Add the image to the RunnerTests target in Xcode ("Copy Bundle Resources")
/// 3. Write a test using `loadTestImage("filename")` and assert expected fields
class OCRImageTests: XCTestCase {

    let ocr = OCRService()

    /// Load a test image from the RunnerTests bundle.
    /// Supports PNG and JPEG formats.
    func loadTestImage(_ name: String, ext: String = "png") -> CGImage? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            return nil
        }
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return uiImage.cgImage
    }

    // MARK: - Template Tests
    // Uncomment and fill in when you add actual slip images to Fixtures/Images/

    /*
    func testFullPipeline_SCB_basicTransfer() {
        guard let image = loadTestImage("scb_basic_transfer") else {
            XCTFail("Missing test image: scb_basic_transfer.png — add it to Fixtures/Images/ and RunnerTests target")
            return
        }

        let result = ocr.processImageForPaymentSlip(cgImage: image, assetId: "test-scb")
        XCTAssertNotNil(result, "Should detect as a payment slip (amount > 0)")

        // Uncomment and set expected values:
        // XCTAssertEqual(result?["amount"] as? Double, 1500.00)
        // XCTAssertEqual(result?["referenceId"] as? String, "ABC123456")
        // XCTAssertEqual(result?["senderName"] as? String, "...")
        // XCTAssertEqual(result?["receiverName"] as? String, "...")
    }

    func testFullPipeline_KBankMake_basicTransfer() {
        guard let image = loadTestImage("kbank_make_basic") else {
            XCTFail("Missing test image: kbank_make_basic.png")
            return
        }

        let result = ocr.processImageForPaymentSlip(cgImage: image, assetId: "test-make")
        XCTAssertNotNil(result, "Should detect as a payment slip")
    }

    func testFullPipeline_KBankPlus_basicTransfer() {
        guard let image = loadTestImage("kbank_plus_basic") else {
            XCTFail("Missing test image: kbank_plus_basic.png")
            return
        }

        let result = ocr.processImageForPaymentSlip(cgImage: image, assetId: "test-kplus")
        XCTAssertNotNil(result, "Should detect as a payment slip")
    }
    */

    // MARK: - OCR recognizeText Direct Test

    /*
    func testRecognizeText_returnsNonEmptyText() {
        guard let image = loadTestImage("scb_basic_transfer") else {
            XCTFail("Missing test image")
            return
        }

        let (text, amount, date) = ocr.recognizeText(from: image)
        XCTAssertFalse(text.isEmpty, "OCR should extract some text from the image")
        XCTAssertNotNil(amount, "Should extract an amount from a payment slip")
        XCTAssertNotNil(date, "Should extract a date from a payment slip")
    }
    */

    // MARK: - Non-Slip Image Rejection

    /*
    func testNonSlipImage_returnsNil() {
        guard let image = loadTestImage("non_slip_photo") else {
            XCTFail("Missing test image: non_slip_photo.png")
            return
        }

        let result = ocr.processImageForPaymentSlip(cgImage: image, assetId: "test-non-slip")
        XCTAssertNil(result, "Non-payment images should return nil (amount <= 0)")
    }
    */
}
