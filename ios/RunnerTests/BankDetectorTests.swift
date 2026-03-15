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

    // MARK: - Cross-Bank Transfer Detection
    // These tests verify that the issuing bank (header) wins over the receiver bank (body)
    // when both bank names appear in the same slip OCR text.

    func testDetect_TTB_crossBank_receiverIsKTB() {
        // TTBFixtures.ttbTouchTransfer: "ttb touch" header, receiver account at ธนาคารกรุงไทย
        // KTB anchor (ธนาคารกรุงไทย) must NOT win over TTB anchor (ttb) which is earlier.
        let bankType = BankDetector.detect(TTBFixtures.ttbTouchTransfer)
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_GSB_crossBank_receiverIsBBL() {
        // GSBFixtures.mymoColonStyle: "GSB" header, receiver account at ธนาคารกรุงเทพ
        // BBL anchor (ธนาคารกรุงเทพ) must NOT win over GSB anchor (GSB) which is earlier.
        let bankType = BankDetector.detect(GSBFixtures.mymoColonStyle)
        XCTAssertEqual(bankType, .gsb)
    }

    func testDetect_KTB_crossBank_receiverIsKBank() {
        // KTBFixtures.ktbAppTransfer: "ธนาคารกรุงไทย" header, receiver account at ธนาคารกสิกรไทย
        // KBank anchor (ธนาคารกสิกรไทย) must NOT win over KTB anchor (ธนาคารกรุงไทย) which is earlier.
        let bankType = BankDetector.detect(KTBFixtures.ktbAppTransfer)
        XCTAssertEqual(bankType, .ktb)
    }

    func testDetect_TTB_crossBank_receiverIsSCB() {
        let text = """
ttb touch
โอนเงินสำเร็จ
ชื่อบัญชีผู้โอน
นายสมชาย ใจดี
xxx-x-x1234-x
ชื่อบัญชีผู้รับ
นางสาวรับเงิน ใจดี
xxx-x-x5678-x
ธนาคารไทยพาณิชย์
จำนวนเงิน 800.00 บาท
"""
        // SCB (ธนาคารไทยพาณิชย์) appears only as receiver bank; TTB (ttb) is the header.
        let bankType = BankDetector.detect(text)
        XCTAssertEqual(bankType, .ttb)
    }

    func testDetect_KTB_crossBank_receiverIsBBL() {
        let text = """
ธนาคารกรุงไทย
โอนเงินสำเร็จ
ชื่อผู้โอน
นายทดสอบ ระบบ
xxx-x-x9999-x
ชื่อผู้รับ
บริษัท ทดสอบ จำกัด
xxx-x-x3333-x
ธนาคารกรุงเทพ
จำนวนเงิน 3,000.00 บาท
"""
        // BBL (ธนาคารกรุงเทพ) appears only as receiver bank; KTB (ธนาคารกรุงไทย) is the header.
        let bankType = BankDetector.detect(text)
        XCTAssertEqual(bankType, .ktb)
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
