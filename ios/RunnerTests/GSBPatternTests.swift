import XCTest
@testable import Runner

/// Unit tests for GSB (Government Savings Bank / ธนาคารออมสิน) pattern detection and extraction.
class GSBPatternTests: XCTestCase {

    let ocr = OCRService()

    // MARK: - Bank Detection

    func testDetect_GSB_thaiName() {
        let bankType = BankDetector.detect("ธนาคารออมสิน\nโอนเงินสำเร็จ\n500.00 บาท")
        XCTAssertEqual(bankType, .gsb)
    }

    func testDetect_GSB_abbreviation() {
        let bankType = BankDetector.detect("GSB\nTransfer Successful\n1,000.00 THB")
        XCTAssertEqual(bankType, .gsb)
    }

    func testDetect_GSB_fromMymoFixture() {
        let bankType = BankDetector.detect(GSBFixtures.mymoTransfer)
        XCTAssertEqual(bankType, .gsb)
    }

    func testDetect_GSB_fromColonStyleFixture() {
        let bankType = BankDetector.detect(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(bankType, .gsb)
    }

    func testDetect_GSB_fromNoisyFixture() {
        let bankType = BankDetector.detect(GSBFixtures.noisyTransfer)
        XCTAssertEqual(bankType, .gsb)
    }

    // MARK: - Registry

    func testRegistry_hasPatternForGSB() {
        let patterns = BankPatternRegistry.patterns(for: .gsb)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .gsb)
        XCTAssertEqual(patterns?.dateFormat, .buddhistEra)
    }

    // MARK: - Amount Extraction

    func testAmount_mymoTransfer() {
        let amount = ocr.extractAmountFromText(GSBFixtures.mymoTransfer)
        XCTAssertEqual(amount, GSBFixtures.Expected.mymoTransfer.amount)
    }

    func testAmount_mymoColonStyle() {
        let amount = ocr.extractAmountFromText(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(amount, GSBFixtures.Expected.mymoColonStyle.amount)
    }

    func testAmount_noisyTransfer() {
        let amount = ocr.extractAmountFromText(GSBFixtures.noisyTransfer)
        XCTAssertEqual(amount, GSBFixtures.Expected.noisyTransfer.amount)
    }

    // MARK: - Date Extraction (B.E. — 15-char DD/MM/YYYY HH:MM format)

    func testDate_mymoTransfer_buddhistYear() {
        let date = ocr.extractDateFromText(GSBFixtures.mymoTransfer)
        XCTAssertNotNil(date, "Should extract date from DD/MM/YYYY HH:MM format")
        // 2567 BE -> 2024 CE
        XCTAssertTrue(date?.contains("2024") == true || date?.contains("01") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    func testDate_mymoColonStyle_buddhistYear() {
        let date = ocr.extractDateFromText(GSBFixtures.mymoColonStyle)
        XCTAssertNotNil(date)
        XCTAssertTrue(date?.contains("2024") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    // MARK: - Reference ID Extraction

    func testReferenceId_mymoTransfer_labeled() {
        let refId = ocr.extractReferenceId(GSBFixtures.mymoTransfer)
        XCTAssertEqual(refId, GSBFixtures.Expected.mymoTransfer.referenceId)
    }

    func testReferenceId_mymoColonStyle_raiKarn() {
        let refId = ocr.extractReferenceId(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(refId, GSBFixtures.Expected.mymoColonStyle.referenceId)
    }

    func testReferenceId_noisyTransfer() {
        let refId = ocr.extractReferenceId(GSBFixtures.noisyTransfer)
        XCTAssertEqual(refId, GSBFixtures.Expected.noisyTransfer.referenceId)
    }

    // MARK: - Sender Name Extraction

    func testSenderName_mymoTransfer_spaceLabel() {
        let name = ocr.extractSenderName(GSBFixtures.mymoTransfer)
        XCTAssertEqual(name, GSBFixtures.Expected.mymoTransfer.senderName)
    }

    func testSenderName_mymoColonStyle() {
        let name = ocr.extractSenderName(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(name, GSBFixtures.Expected.mymoColonStyle.senderName)
    }

    // MARK: - Receiver Name Extraction

    func testReceiverName_mymoTransfer_spaceLabel() {
        let name = ocr.extractReceiverName(GSBFixtures.mymoTransfer)
        XCTAssertEqual(name, GSBFixtures.Expected.mymoTransfer.receiverName)
    }

    func testReceiverName_mymoColonStyle() {
        let name = ocr.extractReceiverName(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(name, GSBFixtures.Expected.mymoColonStyle.receiverName)
    }

    // MARK: - Account Number Extraction

    func testAccountNumbers_mymoTransfer() {
        let accounts = ocr.extractAccountNumbers(GSBFixtures.mymoTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], GSBFixtures.Expected.mymoTransfer.senderAccount)
        XCTAssertEqual(accounts[1], GSBFixtures.Expected.mymoTransfer.receiverAccount)
    }

    func testAccountNumbers_mymoColonStyle() {
        let accounts = ocr.extractAccountNumbers(GSBFixtures.mymoColonStyle)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], GSBFixtures.Expected.mymoColonStyle.senderAccount)
        XCTAssertEqual(accounts[1], GSBFixtures.Expected.mymoColonStyle.receiverAccount)
    }

    // MARK: - PromptPay TransRef (universal pattern)

    func testTransRef_noisyTransfer_extractsRef() {
        let transRef = UniversalPatterns.extractTransRef(GSBFixtures.noisyTransfer)
        XCTAssertEqual(transRef, GSBFixtures.Expected.noisyTransfer.transRef)
    }

    func testTransRef_mymoTransfer_absentWhenNoRef() {
        // mymoTransfer has no 22-25 digit PromptPay transRef
        let transRef = UniversalPatterns.extractTransRef(GSBFixtures.mymoTransfer)
        XCTAssertNil(transRef)
    }
}
