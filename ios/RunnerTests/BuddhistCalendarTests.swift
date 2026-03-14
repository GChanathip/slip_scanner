import XCTest
@testable import Runner

/// Tests for Buddhist calendar detection and conversion in OCRService.
class BuddhistCalendarTests: XCTestCase {

    let ocr = OCRService()

    // MARK: - containsBuddhistYear

    func testContainsBuddhistYear_fourDigit_2567() {
        XCTAssertTrue(ocr.containsBuddhistYear("15 ม.ค. 2567"))
    }

    func testContainsBuddhistYear_fourDigit_2568() {
        XCTAssertTrue(ocr.containsBuddhistYear("1 ก.พ. 2568"))
    }

    func testContainsBuddhistYear_twoDigit_67() {
        XCTAssertTrue(ocr.containsBuddhistYear("15 ม.ค. 67"))
    }

    func testContainsBuddhistYear_twoDigit_68() {
        XCTAssertTrue(ocr.containsBuddhistYear("1 ก.พ. 68"))
    }

    func testContainsBuddhistYear_gregorian_2024() {
        // 2024 does NOT match 25xx pattern
        XCTAssertFalse(ocr.containsBuddhistYear("15 Jan 2024"))
    }

    func testContainsBuddhistYear_noYear() {
        XCTAssertFalse(ocr.containsBuddhistYear("no year here"))
    }

    // MARK: - convertBuddhistToGregorian

    func testConvertBuddhistToGregorian_fourDigit_jan() {
        let result = ocr.convertBuddhistToGregorian("15 ม.ค. 2567")
        // ม.ค. -> /01/, 2567 -> 2024, spaces removed
        XCTAssertEqual(result, "15/01/2024")
    }

    func testConvertBuddhistToGregorian_fourDigit_dec() {
        let result = ocr.convertBuddhistToGregorian("28 ธ.ค. 2567")
        XCTAssertEqual(result, "28/12/2024")
    }

    func testConvertBuddhistToGregorian_fourDigit_feb() {
        let result = ocr.convertBuddhistToGregorian("10 ก.พ. 2567")
        XCTAssertEqual(result, "10/02/2024")
    }

    func testConvertBuddhistToGregorian_fourDigit_mar() {
        let result = ocr.convertBuddhistToGregorian("20 มี.ค. 2567")
        XCTAssertEqual(result, "20/03/2024")
    }

    func testConvertBuddhistToGregorian_fourDigit_jun() {
        let result = ocr.convertBuddhistToGregorian("5 มิ.ย. 2567")
        XCTAssertEqual(result, "5/06/2024")
    }

    func testConvertBuddhistToGregorian_twoDigit_67() {
        let result = ocr.convertBuddhistToGregorian("15 ม.ค. 67")
        // 67 -> 2500 + 67 - 543 = 2024
        XCTAssertEqual(result, "15/01/2024")
    }

    func testConvertBuddhistToGregorian_twoDigit_68() {
        let result = ocr.convertBuddhistToGregorian("1 ก.พ. 68")
        // 68 -> 2500 + 68 - 543 = 2025
        XCTAssertEqual(result, "1/02/2025")
    }

    // MARK: - normalizeToISODate

    func testNormalizeToISODate_slashFormat_ddMMyyyy() {
        XCTAssertEqual(ocr.normalizeToISODate("15/01/2024"), "2024-01-15")
    }

    func testNormalizeToISODate_isoFormat() {
        XCTAssertEqual(ocr.normalizeToISODate("2024-01-15"), "2024-01-15")
    }

    func testNormalizeToISODate_englishMonth_short() {
        XCTAssertEqual(ocr.normalizeToISODate("15 Jan 2024"), "2024-01-15")
    }

    func testNormalizeToISODate_englishMonth_full() {
        XCTAssertEqual(ocr.normalizeToISODate("15 January 2024"), "2024-01-15")
    }

    func testNormalizeToISODate_dashFormat_ddMMyyyy() {
        XCTAssertEqual(ocr.normalizeToISODate("15-01-2024"), "2024-01-15")
    }

    func testNormalizeToISODate_unknownFormat_returnsOriginal() {
        XCTAssertEqual(ocr.normalizeToISODate("garbage"), "garbage")
    }

    func testNormalizeToISODate_trimmedWhitespace() {
        XCTAssertEqual(ocr.normalizeToISODate("  2024-01-15  "), "2024-01-15")
    }
}
