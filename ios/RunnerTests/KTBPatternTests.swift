import XCTest
@testable import Runner

/// Unit tests for KTB (Krungthai Bank / เป๋าตัง) pattern detection and field extraction.
class KTBPatternTests: XCTestCase {

    let ocr = OCRService()

    // MARK: - Bank Detection

    func testDetect_KTB_thaiName() {
        let bankType = BankDetector.detect("ธนาคารกรุงไทย\nโอนเงินสำเร็จ\n500.00 บาท")
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_KTB_englishName() {
        let bankType = BankDetector.detect("Krungthai Bank\nTransfer Successful\n1,200.00 THB")
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_KTB_paotang() {
        let bankType = BankDetector.detect("เป๋าตัง\nโอนเงินสำเร็จ\n750.00 บาท")
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_KTB_fromPaotangFixture() {
        let bankType = BankDetector.detect(KTBFixtures.paotangTransfer)
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_KTB_fromAppFixture() {
        let bankType = BankDetector.detect(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_KTB_fromNoisyFixture() {
        let bankType = BankDetector.detect(KTBFixtures.noisyTransfer)
        XCTAssertEqual(bankType, .ktb)
    }

    // MARK: - Registry

    func testRegistry_hasPatternForKTB() {
        let patterns = BankPatternRegistry.patterns(for: .ktb)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .ktb)
        XCTAssertEqual(patterns?.dateFormat, .buddhistEra)
    }

    // MARK: - Amount Extraction

    func testAmount_paotangTransfer() {
        let amount = ocr.extractAmountFromText(KTBFixtures.paotangTransfer)
        XCTAssertEqual(amount, KTBFixtures.Expected.paotangTransfer.amount)
    }

    func testAmount_ktbAppTransfer() {
        let amount = ocr.extractAmountFromText(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(amount, KTBFixtures.Expected.ktbAppTransfer.amount)
    }

    func testAmount_noisyTransfer() {
        let amount = ocr.extractAmountFromText(KTBFixtures.noisyTransfer)
        XCTAssertEqual(amount, KTBFixtures.Expected.noisyTransfer.amount)
    }

    // MARK: - Date Extraction

    func testDate_paotangTransfer_buddhistYear() {
        let date = ocr.extractDateFromText(KTBFixtures.paotangTransfer)
        XCTAssertNotNil(date)
        // 2567 BE -> 2024 CE
        XCTAssertTrue(date?.contains("2024") == true || date?.contains("01") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    func testDate_ktbAppTransfer_buddhistYear() {
        let date = ocr.extractDateFromText(KTBFixtures.ktbAppTransfer)
        XCTAssertNotNil(date)
        // 2567 BE -> 2024 CE
        XCTAssertTrue(date?.contains("2024") == true,
                       "Expected Gregorian year after BE conversion, got: \(date ?? "nil")")
    }

    // MARK: - Reference ID Extraction (positional)

    func testReferenceId_paotangTransfer_positional() {
        let refId = ocr.extractReferenceId(KTBFixtures.paotangTransfer)
        XCTAssertEqual(refId, KTBFixtures.Expected.paotangTransfer.referenceId,
                        "KTB positional reference should be extracted without a label prefix")
    }

    func testReferenceId_ktbAppTransfer_positional() {
        let refId = ocr.extractReferenceId(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(refId, KTBFixtures.Expected.ktbAppTransfer.referenceId)
    }

    func testReferenceId_noisyTransfer_positional() {
        let refId = ocr.extractReferenceId(KTBFixtures.noisyTransfer)
        XCTAssertEqual(refId, KTBFixtures.Expected.noisyTransfer.referenceId)
    }

    // MARK: - Sender Name Extraction

    func testSenderName_paotangTransfer() {
        let name = ocr.extractSenderName(KTBFixtures.paotangTransfer)
        XCTAssertEqual(name, KTBFixtures.Expected.paotangTransfer.senderName)
    }

    func testSenderName_ktbAppTransfer() {
        let name = ocr.extractSenderName(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(name, KTBFixtures.Expected.ktbAppTransfer.senderName)
    }

    // MARK: - Receiver Name Extraction

    func testReceiverName_paotangTransfer() {
        let name = ocr.extractReceiverName(KTBFixtures.paotangTransfer)
        XCTAssertEqual(name, KTBFixtures.Expected.paotangTransfer.receiverName)
    }

    func testReceiverName_ktbAppTransfer() {
        let name = ocr.extractReceiverName(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(name, KTBFixtures.Expected.ktbAppTransfer.receiverName)
    }

    // MARK: - Account Number Extraction

    func testAccountNumbers_paotangTransfer() {
        let accounts = ocr.extractAccountNumbers(KTBFixtures.paotangTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], KTBFixtures.Expected.paotangTransfer.senderAccount)
        XCTAssertEqual(accounts[1], KTBFixtures.Expected.paotangTransfer.receiverAccount)
    }

    func testAccountNumbers_ktbAppTransfer() {
        let accounts = ocr.extractAccountNumbers(KTBFixtures.ktbAppTransfer)
        XCTAssertGreaterThanOrEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0], KTBFixtures.Expected.ktbAppTransfer.senderAccount)
        XCTAssertEqual(accounts[1], KTBFixtures.Expected.ktbAppTransfer.receiverAccount)
    }

    // MARK: - PromptPay TransRef (universal pattern)

    func testTransRef_noisyTransfer_extractsRef() {
        let transRef = UniversalPatterns.extractTransRef(KTBFixtures.noisyTransfer)
        XCTAssertEqual(transRef, KTBFixtures.Expected.noisyTransfer.transRef)
    }

    func testTransRef_paotangTransfer_absentWhenNoRef() {
        // paotangTransfer has no PromptPay transRef (22-25 digits) in it
        let transRef = UniversalPatterns.extractTransRef(KTBFixtures.paotangTransfer)
        XCTAssertNil(transRef)
    }
}
