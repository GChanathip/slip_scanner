import Foundation

/// GSB (Government Savings Bank / ธนาคารออมสิน) slip OCR text fixtures.
/// Three samples: MyMo app Thai labels, MyMo app colon-style labels, and noisy OCR variant.
enum GSBFixtures {

    // MARK: - OCR Text Samples

    /// Standard MyMo slip — Thai labels, 15-char DD/MM/YYYY HH:MM date, เลขที่อ้างอิง ref.
    static let mymoTransfer = """
ธนาคารออมสิน
โอนเงินสำเร็จ
ผู้โอน นายสมชาย ใจดี
xxx-x-x1234-x
ผู้รับ นางสาวสมหญิง รักดี
xxx-x-x5678-x
จำนวนเงิน 500.00 บาท
15/01/2567 14:30
เลขที่อ้างอิง A123456789
"""

    /// MyMo slip with colon-separated labels and larger amount.
    static let mymoColonStyle = """
GSB
โอนเงินสำเร็จ
ผู้โอน: นายทดสอบ ระบบ
xxx-x-x9999-x
ธนาคารออมสิน
ผู้รับ: บริษัท เทสต์ จำกัด
xxx-x-x3333-x
ธนาคารกรุงเทพ
จำนวนเงิน 12,500.00 บาท
20/03/2567 09:15
เลขที่รายการ GSB202400099
"""

    /// Noisy OCR variant — extra spacing, PromptPay transRef present.
    static let noisyTransfer = """
ธนาคารออมสิน
โอนเงินสำเร็จ
ชื่อผู้โอน: นายทดสอบ นอยซี่
xxx-x-x7777-x
ชื่อผู้รับ: นางสาวรับเงิน ใจดี
xxx-x-x4444-x
จำนวนเงิน   1,200.00 บาท
1234567890123456789012
10/02/2567 11:00
รหัสอ้างอิง TXN240210XYZ
"""

    // MARK: - Expected Values

    struct Expected {
        static let mymoTransfer = (
            amount: 500.00,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            referenceId: "A123456789",
            senderAccount: "1234",
            receiverAccount: "5678"
        )

        static let mymoColonStyle = (
            amount: 12500.00,
            senderName: "นายทดสอบ ระบบ",
            receiverName: "บริษัท เทสต์ จำกัด",
            referenceId: "GSB202400099",
            senderAccount: "9999",
            receiverAccount: "3333"
        )

        static let noisyTransfer = (
            amount: 1200.00,
            senderName: "นายทดสอบ นอยซี่",
            receiverName: "นางสาวรับเงิน ใจดี",
            referenceId: "TXN240210XYZ",
            transRef: "1234567890123456789012"
        )
    }
}
