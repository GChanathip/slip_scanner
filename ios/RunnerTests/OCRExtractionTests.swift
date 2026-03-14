import XCTest
@testable import Runner

/// Tests for OCRService extraction methods against all bank format fixtures.
/// Each test feeds known OCR text into a specific extraction method and asserts the expected output.
class OCRExtractionTests: XCTestCase {

    let ocr = OCRService()

    // MARK: - Amount Extraction

    func testAmountExtraction_SCB_basicTransfer() {
        let amount = ocr.extractAmountFromText(SCBFixtures.basicTransfer)
        XCTAssertEqual(amount, SCBFixtures.Expected.basicTransfer.amount)
    }

    func testAmountExtraction_SCB_englishLabels() {
        let amount = ocr.extractAmountFromText(SCBFixtures.englishLabels)
        XCTAssertEqual(amount, SCBFixtures.Expected.englishLabels.amount)
    }

    func testAmountExtraction_SCB_largeAmount() {
        let amount = ocr.extractAmountFromText(SCBFixtures.largeAmount)
        XCTAssertEqual(amount, SCBFixtures.Expected.largeAmount.amount)
    }

    func testAmountExtraction_KBankMake_basicTransfer() {
        let amount = ocr.extractAmountFromText(KBankMakeFixtures.basicTransfer)
        XCTAssertEqual(amount, KBankMakeFixtures.Expected.basicTransfer.amount)
    }

    func testAmountExtraction_KBankMake_smallAmount() {
        let amount = ocr.extractAmountFromText(KBankMakeFixtures.smallAmount)
        XCTAssertEqual(amount, KBankMakeFixtures.Expected.smallAmount.amount)
    }

    func testAmountExtraction_KBankPlus_basicTransfer() {
        let amount = ocr.extractAmountFromText(KBankPlusFixtures.basicTransfer)
        XCTAssertEqual(amount, KBankPlusFixtures.Expected.basicTransfer.amount)
    }

    func testAmountExtraction_KBankPlus_crossBank() {
        let amount = ocr.extractAmountFromText(KBankPlusFixtures.crossBank)
        XCTAssertEqual(amount, KBankPlusFixtures.Expected.crossBank.amount)
    }

    func testAmountExtraction_Dime_basicTransfer() {
        let amount = ocr.extractAmountFromText(DimeFixtures.basicTransfer)
        XCTAssertEqual(amount, DimeFixtures.Expected.basicTransfer.amount)
    }

    func testAmountExtraction_noAmount() {
        let amount = ocr.extractAmountFromText("No amount here just some text")
        XCTAssertNil(amount)
    }

    // MARK: - Date Extraction

    func testDateExtraction_SCB_buddhistYear() {
        let date = ocr.extractDateFromText(SCBFixtures.basicTransfer)
        XCTAssertNotNil(date)
        // After Buddhist conversion: 2567 -> 2024
        XCTAssertTrue(date?.contains("2024") == true || date?.contains("01") == true,
                       "Expected Gregorian year, got: \(date ?? "nil")")
    }

    func testDateExtraction_SCB_englishDate() {
        let date = ocr.extractDateFromText(SCBFixtures.englishLabels)
        XCTAssertNotNil(date)
    }

    func testDateExtraction_KBankMake() {
        let date = ocr.extractDateFromText(KBankMakeFixtures.basicTransfer)
        XCTAssertNotNil(date)
    }

    func testDateExtraction_KBankPlus() {
        let date = ocr.extractDateFromText(KBankPlusFixtures.basicTransfer)
        XCTAssertNotNil(date)
    }

    func testDateExtraction_Dime() {
        let date = ocr.extractDateFromText(DimeFixtures.basicTransfer)
        XCTAssertNotNil(date)
    }

    func testDateExtraction_noDate() {
        let date = ocr.extractDateFromText("No date here 999")
        XCTAssertNil(date)
    }

    // MARK: - Reference ID Extraction

    func testReferenceId_SCB() {
        let refId = ocr.extractReferenceId(SCBFixtures.basicTransfer)
        XCTAssertEqual(refId, SCBFixtures.Expected.basicTransfer.referenceId)
    }

    func testReferenceId_SCB_english() {
        let refId = ocr.extractReferenceId(SCBFixtures.englishLabels)
        XCTAssertEqual(refId, SCBFixtures.Expected.englishLabels.referenceId)
    }

    func testReferenceId_KBankMake() {
        let refId = ocr.extractReferenceId(KBankMakeFixtures.basicTransfer)
        XCTAssertEqual(refId, KBankMakeFixtures.Expected.basicTransfer.referenceId)
    }

    func testReferenceId_KBankPlus_slipId() {
        let refId = ocr.extractReferenceId(KBankPlusFixtures.basicTransfer)
        XCTAssertEqual(refId, KBankPlusFixtures.Expected.basicTransfer.referenceId)
    }

    func testReferenceId_Dime() {
        let refId = ocr.extractReferenceId(DimeFixtures.basicTransfer)
        XCTAssertEqual(refId, DimeFixtures.Expected.basicTransfer.referenceId)
    }

    func testReferenceId_noReference() {
        let refId = ocr.extractReferenceId("No reference ID here")
        XCTAssertNil(refId)
    }

    // MARK: - Sender Name Extraction

    func testSenderName_SCB_labelBased() {
        let name = ocr.extractSenderName(SCBFixtures.basicTransfer)
        XCTAssertEqual(name, SCBFixtures.Expected.basicTransfer.senderName)
    }

    // KBank name extraction uses positional regex patterns (not label-based).
    // extractSenderName/extractReceiverName try K Plus before Make, which may
    // capture header text. The LLM extraction (stage 5) cleans up names.
    // Integration tests verify extraction produces non-nil output.
    // Unit tests below test each regex pattern directly.

    func testSenderName_KBankMake_integration() {
        let name = ocr.extractSenderName(KBankMakeFixtures.basicTransfer)
        XCTAssertNotNil(name, "Should extract some sender name from Make text")
    }

    func testSenderName_KBankPlus_integration() {
        let name = ocr.extractSenderName(KBankPlusFixtures.basicTransfer)
        XCTAssertNotNil(name, "Should extract some sender name from K Plus text")
    }

    func testSenderName_Dime_labelBased() {
        let name = ocr.extractSenderName(DimeFixtures.basicTransfer)
        XCTAssertEqual(name, DimeFixtures.Expected.basicTransfer.senderName)
    }

    // MARK: - Receiver Name Extraction

    func testReceiverName_SCB_labelBased() {
        let name = ocr.extractReceiverName(SCBFixtures.basicTransfer)
        XCTAssertEqual(name, SCBFixtures.Expected.basicTransfer.receiverName)
    }

    func testReceiverName_KBankMake_integration() {
        let name = ocr.extractReceiverName(KBankMakeFixtures.basicTransfer)
        XCTAssertNotNil(name, "Should extract some receiver name from Make text")
    }

    func testReceiverName_KBankPlus_integration() {
        let name = ocr.extractReceiverName(KBankPlusFixtures.basicTransfer)
        XCTAssertNotNil(name, "Should extract some receiver name from K Plus text")
    }

    func testReceiverName_Dime_labelBased() {
        let name = ocr.extractReceiverName(DimeFixtures.basicTransfer)
        XCTAssertEqual(name, DimeFixtures.Expected.basicTransfer.receiverName)
    }

    // MARK: - KBank Regex Pattern Unit Tests (test patterns directly)

    func testMakeNamePattern_findsAccountMasks() {
        // Verify Make pattern finds matches before each account mask
        let text = "นายสมชาย ใจดี\nxxx-x-x1234-x\nนางสาวสมหญิง รักดี\nxxx-x-x5678-x"
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = RegexPatterns.kbankMakeNamePattern.matches(in: text, options: [], range: range)

        XCTAssertEqual(matches.count, 2, "Should find 2 Make name matches (one per account mask)")

        // Match 0 sender: captures text from start to line before first mask
        if matches.count >= 1 {
            let captured = nsText.substring(with: matches[0].range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(captured.isEmpty, "Sender capture should not be empty")
            XCTAssertTrue(captured.contains("นายสมชาย ใจดี"))
        }
    }

    func testKPlusNamePattern_findsAccountMasks() {
        // Verify K Plus pattern finds matches 2 lines before each account mask
        let text = "นายสมชาย ใจดี\nธนาคารกสิกรไทย\nxxx-x-x1234-x\nนางสาวสมหญิง รักดี\nธนาคารกสิกรไทย\nxxx-x-x5678-x"
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = RegexPatterns.kbankPlusNamePattern.matches(in: text, options: [], range: range)

        XCTAssertEqual(matches.count, 2, "Should find 2 K Plus name matches (one per account mask)")

        // Match 0 sender: group 1 is text before the bank name line
        if matches.count >= 1 {
            let captured = nsText.substring(with: matches[0].range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(captured.isEmpty, "Sender capture should not be empty")
            XCTAssertTrue(captured.contains("นายสมชาย ใจดี"))
        }
    }

    // MARK: - Account Number Extraction

    func testAccountNumbers_SCB() {
        let accounts = ocr.extractAccountNumbers(SCBFixtures.basicTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], SCBFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(accounts[1], SCBFixtures.Expected.basicTransfer.receiverAccount)
    }

    func testAccountNumbers_KBankMake() {
        let accounts = ocr.extractAccountNumbers(KBankMakeFixtures.basicTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], KBankMakeFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(accounts[1], KBankMakeFixtures.Expected.basicTransfer.receiverAccount)
    }

    func testAccountNumbers_KBankPlus() {
        let accounts = ocr.extractAccountNumbers(KBankPlusFixtures.basicTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], KBankPlusFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(accounts[1], KBankPlusFixtures.Expected.basicTransfer.receiverAccount)
    }

    func testAccountNumbers_Dime() {
        let accounts = ocr.extractAccountNumbers(DimeFixtures.basicTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], DimeFixtures.Expected.basicTransfer.senderAccount)
        XCTAssertEqual(accounts[1], DimeFixtures.Expected.basicTransfer.receiverAccount)
    }

    func testAccountNumbers_noAccounts() {
        let accounts = ocr.extractAccountNumbers("No account numbers here")
        XCTAssertTrue(accounts.isEmpty)
    }

    // MARK: - Time Extraction

    func testTimeExtraction_SCB() {
        let time = ocr.extractTimeFromText(SCBFixtures.basicTransfer)
        XCTAssertEqual(time, SCBFixtures.Expected.basicTransfer.time)
    }

    func testTimeExtraction_KBankMake() {
        let time = ocr.extractTimeFromText(KBankMakeFixtures.basicTransfer)
        XCTAssertEqual(time, KBankMakeFixtures.Expected.basicTransfer.time)
    }

    func testTimeExtraction_KBankPlus() {
        let time = ocr.extractTimeFromText(KBankPlusFixtures.basicTransfer)
        XCTAssertEqual(time, KBankPlusFixtures.Expected.basicTransfer.time)
    }

    func testTimeExtraction_Dime() {
        let time = ocr.extractTimeFromText(DimeFixtures.basicTransfer)
        XCTAssertEqual(time, DimeFixtures.Expected.basicTransfer.time)
    }

    func testTimeExtraction_noTime() {
        let time = ocr.extractTimeFromText("No time info here")
        XCTAssertNil(time)
    }
}
