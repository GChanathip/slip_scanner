import XCTest
@testable import Runner

/// Tests for OCRService.buildSlipResult() — the full text-to-dictionary assembly.
/// Verifies that all extracted fields are correctly assembled into the platform channel dictionary.
class BuildSlipResultTests: XCTestCase {

    let ocr = OCRService()

    func testBuildSlipResult_SCB_basicTransfer() {
        let result = ocr.buildSlipResult(
            text: SCBFixtures.basicTransfer,
            amount: SCBFixtures.Expected.basicTransfer.amount,
            date: SCBFixtures.Expected.basicTransfer.date,
            identifier: "test-asset-scb-001"
        )

        XCTAssertEqual(result["amount"] as? Double, SCBFixtures.Expected.basicTransfer.amount)
        XCTAssertEqual(result["assetId"] as? String, "test-asset-scb-001")
        XCTAssertEqual(result["referenceId"] as? String, SCBFixtures.Expected.basicTransfer.referenceId)
        XCTAssertEqual(result["senderName"] as? String, SCBFixtures.Expected.basicTransfer.senderName)
        XCTAssertEqual(result["receiverName"] as? String, SCBFixtures.Expected.basicTransfer.receiverName)
        XCTAssertEqual(result["senderAccount"] as? String, SCBFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(result["receiverAccount"] as? String, SCBFixtures.Expected.basicTransfer.receiverAccount)
        XCTAssertEqual(result["time"] as? String, SCBFixtures.Expected.basicTransfer.time)

        // Text should be present and not empty
        let text = result["text"] as? String ?? ""
        XCTAssertFalse(text.isEmpty)

        // createdAt should be an ISO timestamp
        let createdAt = result["createdAt"] as? String ?? ""
        XCTAssertTrue(createdAt.contains("T"))

        // Date should be normalized to ISO format
        let date = result["date"] as? String ?? ""
        XCTAssertFalse(date.isEmpty)
    }

    func testBuildSlipResult_KBankMake_basicTransfer() {
        let result = ocr.buildSlipResult(
            text: KBankMakeFixtures.basicTransfer,
            amount: KBankMakeFixtures.Expected.basicTransfer.amount,
            date: "10/02/2024",
            identifier: "test-asset-make-001"
        )

        XCTAssertEqual(result["amount"] as? Double, KBankMakeFixtures.Expected.basicTransfer.amount)
        XCTAssertEqual(result["referenceId"] as? String, KBankMakeFixtures.Expected.basicTransfer.referenceId)
        XCTAssertEqual(result["senderAccount"] as? String, KBankMakeFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(result["receiverAccount"] as? String, KBankMakeFixtures.Expected.basicTransfer.receiverAccount)
        XCTAssertEqual(result["time"] as? String, KBankMakeFixtures.Expected.basicTransfer.time)
    }

    func testBuildSlipResult_KBankPlus_basicTransfer() {
        let result = ocr.buildSlipResult(
            text: KBankPlusFixtures.basicTransfer,
            amount: KBankPlusFixtures.Expected.basicTransfer.amount,
            date: "28/12/2024",
            identifier: "test-asset-kplus-001"
        )

        XCTAssertEqual(result["amount"] as? Double, KBankPlusFixtures.Expected.basicTransfer.amount)
        XCTAssertEqual(result["referenceId"] as? String, KBankPlusFixtures.Expected.basicTransfer.referenceId)
        XCTAssertEqual(result["senderAccount"] as? String, KBankPlusFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(result["receiverAccount"] as? String, KBankPlusFixtures.Expected.basicTransfer.receiverAccount)
        XCTAssertEqual(result["time"] as? String, KBankPlusFixtures.Expected.basicTransfer.time)
    }

    func testBuildSlipResult_Dime_basicTransfer() {
        let result = ocr.buildSlipResult(
            text: DimeFixtures.basicTransfer,
            amount: DimeFixtures.Expected.basicTransfer.amount,
            date: "12/07/2024",
            identifier: "test-asset-dime-001"
        )

        XCTAssertEqual(result["amount"] as? Double, DimeFixtures.Expected.basicTransfer.amount)
        XCTAssertEqual(result["referenceId"] as? String, DimeFixtures.Expected.basicTransfer.referenceId)
        XCTAssertEqual(result["senderAccount"] as? String, DimeFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(result["receiverAccount"] as? String, DimeFixtures.Expected.basicTransfer.receiverAccount)
        XCTAssertEqual(result["time"] as? String, DimeFixtures.Expected.basicTransfer.time)
    }

    func testBuildSlipResult_emptyFields_returnEmptyStrings() {
        let result = ocr.buildSlipResult(
            text: "Just some plain text without any slip data",
            amount: 100.00,
            date: nil,
            identifier: "test-no-fields"
        )

        // Missing fields should be empty strings, not nil
        XCTAssertEqual(result["referenceId"] as? String, "")
        XCTAssertEqual(result["senderName"] as? String, "")
        XCTAssertEqual(result["receiverName"] as? String, "")
        XCTAssertEqual(result["senderAccount"] as? String, "")
        XCTAssertEqual(result["receiverAccount"] as? String, "")
        XCTAssertEqual(result["time"] as? String, "")
        XCTAssertEqual(result["date"] as? String, "")
    }

    func testBuildSlipResult_textTruncation() {
        let longText = String(repeating: "a", count: 20000)
        let result = ocr.buildSlipResult(
            text: longText,
            amount: 100.00,
            date: nil,
            identifier: "test-truncation"
        )

        let text = result["text"] as? String ?? ""
        XCTAssertEqual(text.count, 10000, "Text should be truncated to 10000 characters")
    }

    func testBuildSlipResult_identifierTruncation() {
        let longId = String(repeating: "x", count: 200)
        let result = ocr.buildSlipResult(
            text: "test",
            amount: 100.00,
            date: nil,
            identifier: longId
        )

        let assetId = result["assetId"] as? String ?? ""
        XCTAssertEqual(assetId.count, 100, "Asset ID should be truncated to 100 characters")
    }
}
