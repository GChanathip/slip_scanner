import Foundation

/// KTB (Krungthai Bank / เป๋าตัง) slip OCR text fixtures.
/// Three samples: clean เป๋าตัง transfer, clean Krungthai app transfer, and a noisy OCR variant.
enum KTBFixtures {

    // MARK: - OCR Text Samples

    /// Standard เป๋าตัง (Pao Tang) transfer slip — reference immediately after header.
    static let paotangTransfer = """
เป๋าตัง
โอนเงินสำเร็จ
FT67015XY12345A
ชื่อผู้โอน
นายสมชาย ใจดี
xxx-x-x1234-x
ธนาคารกรุงไทย
ชื่อผู้รับ
นางสาวสมหญิง รักดี
xxx-x-x5678-x
ธนาคารกรุงไทย
จำนวนเงิน
500.00 บาท
15 ม.ค. 2567 14:30
"""

    /// Krungthai Bank app transfer slip — FT-prefix reference, different receiver bank.
    static let ktbAppTransfer = """
ธนาคารกรุงไทย
โอนเงินสำเร็จ
KTB240115001234
ชื่อผู้โอน
นายทดสอบ ระบบ
xxx-x-x9999-x
ธนาคารกรุงไทย
ชื่อผู้รับ
บริษัท เทสต์ จำกัด
xxx-x-x3333-x
ธนาคารกสิกรไทย
จำนวนเงิน
2,500.00 บาท
20 มี.ค. 2567 09:15
"""

    /// Noisy OCR variant — extra whitespace, slightly garbled characters, PromptPay transRef present.
    static let noisyTransfer = """
เป๋าตัง
โอนเงินสำเร็จ
FT67042ABC98765
ชื่อผู้โอน
นายทดสอบ PromptPay
xxx-x-x7777-x
ธนาคารกรุงไทย
ชื่อผู้รับ
นางสาวรับเงิน ใจดี
xxx-x-x4444-x
ธนาคาร กสิกรไทย
จำนวนเงิน  1,200.00  บาท
1234567890123456789012
10 ก.พ. 2567 11:00
"""

    // MARK: - Expected Values

    struct Expected {
        static let paotangTransfer = (
            amount: 500.00,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            referenceId: "FT67015XY12345A",
            senderAccount: "1234",
            receiverAccount: "5678"
        )

        static let ktbAppTransfer = (
            amount: 2500.00,
            senderName: "นายทดสอบ ระบบ",
            receiverName: "บริษัท เทสต์ จำกัด",
            referenceId: "KTB240115001234",
            senderAccount: "9999",
            receiverAccount: "3333"
        )

        static let noisyTransfer = (
            amount: 1200.00,
            senderName: "นายทดสอบ PromptPay",
            receiverName: "นางสาวรับเงิน ใจดี",
            referenceId: "FT67042ABC98765",
            transRef: "1234567890123456789012"
        )
    }
}
