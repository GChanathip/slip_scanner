import Foundation

/// K Plus (KBank K Plus) slip OCR text fixtures.
/// K Plus format: name is TWO lines above the account mask (skip bank name line).
/// Pattern: name\nbankName\nxxx-x-x####-x
/// Positional extraction: match index 0 = sender, match index 1 = receiver.
///
/// IMPORTANT: The K Plus regex `(.*?)\n(?:.*?)\n(?=xxx-x-x\d{4}-x)` with dotMatchesLineSeparators
/// captures text from the previous match (or string start) to 2 lines before the account mask.
/// Place amount/date/reference lines BEFORE the name+bank+account blocks.
enum KBankPlusFixtures {

    // MARK: - OCR Text Samples

    /// Standard K Plus transfer slip
    static let basicTransfer = """
K PLUS
โอนเงิน
จำนวนเงิน 3,500.75
28 ธ.ค. 2567 - 11:30
Slip ID 9876543210
นายสมชาย ใจดี
ธนาคารกสิกรไทย
xxx-x-x1234-x
นางสาวสมหญิง รักดี
ธนาคารกสิกรไทย
xxx-x-x5678-x
"""

    /// K Plus cross-bank transfer
    static let crossBank = """
K PLUS
โอนเงิน
จำนวน: 750.00 บาท
1 พ.ย. 2567 - 20:00
นายข้ามธนาคาร ทดสอบ
ธนาคารกสิกรไทย
xxx-x-x4321-x
นางสาวรับเงิน ทดสอบ
ธนาคารกรุงเทพ
xxx-x-x8765-x
"""

    // MARK: - Expected Values

    struct Expected {
        static let basicTransfer = (
            amount: 3500.75,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            senderAccount: "1234",
            receiverAccount: "5678",
            referenceId: "9876543210",
            time: "11:30"
        )

        static let crossBank = (
            amount: 750.00,
            senderName: "นายข้ามธนาคาร ทดสอบ",
            receiverName: "นางสาวรับเงิน ทดสอบ",
            senderAccount: "4321",
            receiverAccount: "8765"
        )
    }
}
