import Foundation

/// TTB (TMBThanachart / ttb touch) slip OCR text fixtures.
/// Three samples: ttb touch style (new brand), TMB legacy style, and noisy OCR variant.
enum TTBFixtures {

    // MARK: - OCR Text Samples

    /// ttb touch style — ชื่อบัญชีผู้โอน/ชื่อบัญชีผู้รับ labels, หมายเลขรายการ reference.
    static let ttbTouchTransfer = """
ttb touch
โอนเงินสำเร็จ
ชื่อบัญชีผู้โอน
นายสมชาย ใจดี
xxx-x-x1234-x
ธนาคารทีเอ็มบีธนชาต
ชื่อบัญชีผู้รับ
นางสาวสมหญิง รักดี
xxx-x-x5678-x
ธนาคารกรุงไทย
จำนวนเงิน 1,500.00 บาท
15 ม.ค. 2567 14:30
หมายเลขรายการ 2401150012345678
"""

    /// TMB Internet Banking legacy style — จาก/ไปยัง labels, เลขที่รายการ reference.
    static let tmbLegacyTransfer = """
TMB Internet Banking
โอนเงินสำเร็จ
จาก
นายทดสอบ ระบบ
xxx-x-x9999-x
ธนาคารทหารไทยธนชาต
ไปยัง
บริษัท เทสต์ จำกัด
xxx-x-x3333-x
ธนาคารกสิกรไทย
จำนวน 2,500.00 บาท
20/03/2567 09:15
เลขที่รายการ TMB202403200099
"""

    /// Noisy OCR variant — ทีเอ็มบีธนชาต anchor, PromptPay transRef, OCR spacing noise.
    static let noisyTransfer = """
ทีเอ็มบีธนชาต
โอนเงินสำเร็จ
ชื่อบัญชีผู้โอน
นายทดสอบ นอยซี่
xxx-x-x7777-x
ชื่อบัญชีผู้รับ
นางสาวรับเงิน ใจดี
xxx-x-x4444-x
จำนวนเงิน   1,200.00  บาท
1234567890123456789012
10 ก.พ. 2567 11:00
รหัสอ้างอิง TXN240210TTB
"""

    // MARK: - Expected Values

    struct Expected {
        static let ttbTouchTransfer = (
            amount: 1500.00,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            referenceId: "2401150012345678",
            senderAccount: "1234",
            receiverAccount: "5678"
        )

        static let tmbLegacyTransfer = (
            amount: 2500.00,
            senderName: "นายทดสอบ ระบบ",
            receiverName: "บริษัท เทสต์ จำกัด",
            referenceId: "TMB202403200099",
            senderAccount: "9999",
            receiverAccount: "3333"
        )

        static let noisyTransfer = (
            amount: 1200.00,
            senderName: "นายทดสอบ นอยซี่",
            receiverName: "นางสาวรับเงิน ใจดี",
            referenceId: "TXN240210TTB",
            transRef: "1234567890123456789012"
        )
    }
}
