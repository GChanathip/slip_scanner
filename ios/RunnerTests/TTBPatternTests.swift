import XCTest
@testable import Runner

/// Unit tests for TTB (TMBThanachart / ttb touch) pattern detection and extraction.
/// Covers dual-branding: ttb touch style and legacy TMB Internet Banking style.
class TTBPatternTests: XCTestCase {

    let ocr = OCRService()

    // MARK: - Bank Detection (dual branding)

    func testDetect_TTB_ttbAbbreviation() {
        let bankType = BankDetector.detect("ttb touch\nโอนเงินสำเร็จ\n500.00 บาท")
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_tmbLegacy() {
        let bankType = BankDetector.detect("TMB Internet Banking\nTransfer Successful")
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_thaiFullName() {
        let bankType = BankDetector.detect("ทีเอ็มบีธนชาต\nโอนเงินสำเร็จ\n1,000.00 บาท")
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_englishFullName() {
        let bankType = BankDetector.detect("TMBThanachart\nโอนเงิน\n2,000.00")
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_fromTouchFixture() {
        let bankType = BankDetector.detect(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_fromLegacyFixture() {
        let bankType = BankDetector.detect(TTBFixtures.tmbLegacyTransfer)
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_TTB_fromNoisyFixture() {
        let bankType = BankDetector.detect(TTBFixtures.noisyTransfer)
        XCTAssertEqual(bankType, .ttb)
    }

    // MARK: - Registry

    func testRegistry_hasPatternForTTB() {
        let patterns = BankPatternRegistry.patterns(for: .ttb)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .ttb)
        XCTAssertEqual(patterns?.dateFormat, .buddhistEra)
    }

    // MARK: - Amount Extraction

    func testAmount_ttbTouchTransfer() {
        let amount = ocr.extractAmountFromText(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(amount, TTBFixtures.Expected.ttbTouchTransfer.amount)
    }

    func testAmount_tmbLegacyTransfer() {
        let amount = ocr.extractAmountFromText(TTBFixtures.tmbLegacyTransfer)
        XCTAssertEqual(amount, TTBFixtures.Expected.tmbLegacyTransfer.amount)
    }

    func testAmount_noisyTransfer() {
        let amount = ocr.extractAmountFromText(TTBFixtures.noisyTransfer)
        XCTAssertEqual(amount, TTBFixtures.Expected.noisyTransfer.amount)
    }

    // MARK: - Date Extraction (B.E.)

    func testDate_ttbTouchTransfer_buddhistYear() {
        let date = ocr.extractDateFromText(TTBFixtures.ttbTouchTransfer)
        XCTAssertNotNil(date)
        // 2567 BE -> 2024 CE
        XCTAssertTrue(date?.contains("2024") == true || date?.contains("01") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    func testDate_tmbLegacyTransfer_buddhistYear() {
        let date = ocr.extractDateFromText(TTBFixtures.tmbLegacyTransfer)
        XCTAssertNotNil(date)
        XCTAssertTrue(date?.contains("2024") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    // MARK: - Reference ID Extraction

    func testReferenceId_ttbTouch_raiKarn() {
        let refId = ocr.extractReferenceId(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(refId, TTBFixtures.Expected.ttbTouchTransfer.referenceId)
    }

    func testReferenceId_tmbLegacy_raiKarn() {
        let refId = ocr.extractReferenceId(TTBFixtures.tmbLegacyTransfer)
        XCTAssertEqual(refId, TTBFixtures.Expected.tmbLegacyTransfer.referenceId)
    }

    func testReferenceId_noisyTransfer() {
        let refId = ocr.extractReferenceId(TTBFixtures.noisyTransfer)
        XCTAssertEqual(refId, TTBFixtures.Expected.noisyTransfer.referenceId)
    }

    // MARK: - Sender Name (dual brand labels)

    func testSenderName_ttbTouch_accountNameLabel() {
        let name = ocr.extractSenderName(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(name, TTBFixtures.Expected.ttbTouchTransfer.senderName)
    }

    func testSenderName_tmbLegacy_jakLabel() {
        let name = ocr.extractSenderName(TTBFixtures.tmbLegacyTransfer)
        XCTAssertEqual(name, TTBFixtures.Expected.tmbLegacyTransfer.senderName)
    }

    // MARK: - Receiver Name (dual brand labels)

    func testReceiverName_ttbTouch_accountNameLabel() {
        let name = ocr.extractReceiverName(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(name, TTBFixtures.Expected.ttbTouchTransfer.receiverName)
    }

    func testReceiverName_tmbLegacy_payangLabel() {
        let name = ocr.extractReceiverName(TTBFixtures.tmbLegacyTransfer)
        XCTAssertEqual(name, TTBFixtures.Expected.tmbLegacyTransfer.receiverName)
    }

    // MARK: - Account Number Extraction

    func testAccountNumbers_ttbTouch() {
        let accounts = ocr.extractAccountNumbers(TTBFixtures.ttbTouchTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], TTBFixtures.Expected.ttbTouchTransfer.senderAccount)
        XCTAssertEqual(accounts[1], TTBFixtures.Expected.ttbTouchTransfer.receiverAccount)
    }

    func testAccountNumbers_tmbLegacy() {
        let accounts = ocr.extractAccountNumbers(TTBFixtures.tmbLegacyTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], TTBFixtures.Expected.tmbLegacyTransfer.senderAccount)
        XCTAssertEqual(accounts[1], TTBFixtures.Expected.tmbLegacyTransfer.receiverAccount)
    }

    // MARK: - PromptPay TransRef (universal pattern)

    func testTransRef_noisyTransfer_extractsRef() {
        let transRef = UniversalPatterns.extractTransRef(TTBFixtures.noisyTransfer)
        XCTAssertEqual(transRef, TTBFixtures.Expected.noisyTransfer.transRef)
    }

    func testTransRef_ttbTouch_absentWhenNoRef() {
        let transRef = UniversalPatterns.extractTransRef(TTBFixtures.ttbTouchTransfer)
        XCTAssertNil(transRef)
    }
}
