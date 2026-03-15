import XCTest
@testable import Runner

/// Tests for BankDetector.detect() — verifies correct bank identification from OCR text.
class BankDetectorTests: XCTestCase {

    // MARK: - SCB Detection

    func testDetect_SCB_thaiName() {
        let bankType = BankDetector.detect("ธนาคารไทยพาณิชย์\nโอนเงินสำเร็จ\n1,500.00 บาท")
        XCTAssertEqual(bankType, .scb)
    }

    func testDetect_SCB_englishName() {
        let bankType = BankDetector.detect("Siam Commercial Bank\nTransfer Successful\n2,350.50 THB")
        XCTAssertEqual(bankType, .scb)
    }

    func testDetect_SCB_abbreviation() {
        let bankType = BankDetector.detect("SCB Easy\nโอนเงิน\n500.00")
        XCTAssertEqual(bankType, .scb)
    }

    func testDetect_SCB_fromFixture() {
        let bankType = BankDetector.detect(SCBFixtures.basicTransfer)
        XCTAssertEqual(bankType, .scb)
    }

    func testDetect_SCB_fromEnglishFixture() {
        let bankType = BankDetector.detect(SCBFixtures.englishLabels)
        XCTAssertEqual(bankType, .scb)
    }

    // MARK: - KBank Detection

    func testDetect_KBank_make() {
        let bankType = BankDetector.detect("Make by KBank\nโอนเงินสำเร็จ\n1,200.00 บาท")
        XCTAssertEqual(bankType, .kbank)
    }

    func testDetect_KBank_kplus() {
        let bankType = BankDetector.detect("K PLUS\nโอนเงิน\n3,500.75")
        XCTAssertEqual(bankType, .kbank)
    }

    func testDetect_KBank_thaiName() {
        let bankType = BankDetector.detect("ธนาคารกสิกรไทย\nรายการโอนเงิน")
        XCTAssertEqual(bankType, .kbank)
    }

    func testDetect_KBank_fromMakeFixture() {
        let bankType = BankDetector.detect(KBankMakeFixtures.basicTransfer)
        XCTAssertEqual(bankType, .kbank)
    }

    func testDetect_KBank_fromPlusFixture() {
        let bankType = BankDetector.detect(KBankPlusFixtures.basicTransfer)
        XCTAssertEqual(bankType, .kbank)
    }

    // MARK: - Dime Detection

    func testDetect_Dime() {
        let bankType = BankDetector.detect("Dime\nโอนเงินสำเร็จ\n500.00 บาท")
        XCTAssertEqual(bankType, .dime)
    }

    func testDetect_Dime_fromFixture() {
        let bankType = BankDetector.detect(DimeFixtures.basicTransfer)
        XCTAssertEqual(bankType, .dime)
    }

    // MARK: - Unknown Detection

    func testDetect_unknown_noAnchors() {
        let bankType = BankDetector.detect("โอนเงินสำเร็จ\n1,500.00 บาท\nรหัสอ้างอิง: ABC123")
        XCTAssertEqual(bankType, .unknown)
    }

    func testDetect_unknown_emptyText() {
        let bankType = BankDetector.detect("")
        XCTAssertEqual(bankType, .unknown)
    }

    // MARK: - TransRef Extraction

    func testTransRef_extractsPromptPayRef() {
        let text = "รายการโอนเงิน\n1234567890123456789012\nจำนวน 500.00"
        let transRef = UniversalPatterns.extractTransRef(text)
        XCTAssertEqual(transRef, "1234567890123456789012")
    }

    func testTransRef_extracts25Digits() {
        let text = "Ref: 1234567890123456789012345\nAmount: 100.00"
        let transRef = UniversalPatterns.extractTransRef(text)
        XCTAssertEqual(transRef, "1234567890123456789012345")
    }

    func testTransRef_ignoresShortNumbers() {
        let text = "จำนวน 1,500.00\nรหัส 123456789"
        let transRef = UniversalPatterns.extractTransRef(text)
        XCTAssertNil(transRef)
    }

    func testTransRef_ignoresTooLongNumbers() {
        let text = "12345678901234567890123456"  // 26 digits
        let transRef = UniversalPatterns.extractTransRef(text)
        XCTAssertNil(transRef)
    }

    // MARK: - BankPatternRegistry

    func testRegistry_hasPatternForSCB() {
        let patterns = BankPatternRegistry.patterns(for: .scb)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .scb)
        XCTAssertEqual(patterns?.dateFormat, .buddhistEra)
    }

    func testRegistry_hasPatternForKBank() {
        let patterns = BankPatternRegistry.patterns(for: .kbank)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .kbank)
    }

    func testRegistry_hasPatternForDime() {
        let patterns = BankPatternRegistry.patterns(for: .dime)
        XCTAssertNotNil(patterns)
        XCTAssertEqual(patterns?.bankType, .dime)
    }

    func testRegistry_returnsNilForUnknown() {
        let patterns = BankPatternRegistry.patterns(for: .unknown)
        XCTAssertNil(patterns)
    }
}
