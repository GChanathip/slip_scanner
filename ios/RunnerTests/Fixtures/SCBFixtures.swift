import Foundation

/// SCB (Siam Commercial Bank) slip OCR text fixtures.
/// To add a new regression test: paste OCR text as a new static constant,
/// add expected values to Expected, write a one-line assertion in the test file.
enum SCBFixtures {

    // MARK: - OCR Text Samples

    /// Standard SCB transfer slip with Thai labels
    static let basicTransfer = """
ธนาคารไทยพาณิชย์
โอนเงินสำเร็จ
จาก
นายสมชาย ใจดี
xxx-xxx456-7
ไปยัง
นางสาวสมหญิง รักดี
xxx-xxx789-0
จำนวนเงิน 1,500.00 บาท
15 ม.ค. 2567 - 14:30
รหัสอ้างอิง: ABC123456
"""

    /// SCB slip with English labels
    static let englishLabels = """
Siam Commercial Bank
Transfer Successful
From
Somchai Jaidi
xxx-xxx456-7
To
Somying Rakdee
xxx-xxx789-0
Amount 2,350.50 THB
Date 15 Jan 2024 - 2:30 PM
Transaction ID: TXN987654
"""

    /// SCB slip with large amount (comma-separated)
    static let largeAmount = """
ธนาคารไทยพาณิชย์
โอนเงินสำเร็จ
จาก
นายทดสอบ ระบบ
xxx-xxx111-2
ไปยัง
บริษัท เทสต์ จำกัด
xxx-xxx333-4
จำนวนเงิน 125,000.00 บาท
20 มี.ค. 2567 - 09:15
รหัสอ้างอิง: XYZ999888
"""

    // MARK: - Expected Values

    struct Expected {
        static let basicTransfer = (
            amount: 1500.00,
            date: "15/01/2024",   // after BE -> Gregorian conversion
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            referenceId: "ABC123456",
            senderAccount: "456-7",
            receiverAccount: "789-0",
            time: "14:30"
        )

        static let englishLabels = (
            amount: 2350.50,
            senderName: "Somchai Jaidi",
            receiverName: "Somying Rakdee",
            referenceId: "TXN987654",
            senderAccount: "456-7",
            receiverAccount: "789-0"
        )

        static let largeAmount = (
            amount: 125000.00,
            senderName: "นายทดสอบ ระบบ",
            receiverName: "บริษัท เทสต์ จำกัด",
            referenceId: "XYZ999888",
            senderAccount: "111-2",
            receiverAccount: "333-4",
            time: "09:15"
        )
    }
}
