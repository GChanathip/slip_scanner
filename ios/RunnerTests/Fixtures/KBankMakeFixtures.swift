import Foundation

/// KBank Make (Make by KBank) slip OCR text fixtures.
/// Make format: name is directly above the account mask line (xxx-x-x####-x).
/// Positional extraction: match index 0 = sender, match index 1 = receiver.
///
/// IMPORTANT: The Make regex `(.*?)\n(?=xxx-x-x\d{4}-x)` with dotMatchesLineSeparators
/// captures ALL text from the previous match (or string start) to the newline before
/// the account mask. Place amount/date/reference lines BEFORE the name+account blocks
/// so the regex only captures the name on each match.
enum KBankMakeFixtures {

    // MARK: - OCR Text Samples

    /// Standard Make transfer slip — amount/date first, then sender/receiver blocks
    static let basicTransfer = """
Make by KBank
โอนเงินสำเร็จ
1,200.00 บาท
10 ก.พ. 2567 - 16:45
เลขที่รายการ:MAKE001234
นายสมชาย ใจดี
xxx-x-x1234-x
นางสาวสมหญิง รักดี
xxx-x-x5678-x
"""

    /// Make slip with small amount (no comma)
    static let smallAmount = """
Make by KBank
โอนเงิน
50.00 บาท
5 มิ.ย. 2567 - 08:00
นายทดสอบ หนึ่ง
xxx-x-x9999-x
นายทดสอบ สอง
xxx-x-x8888-x
"""

    // MARK: - Expected Values

    struct Expected {
        static let basicTransfer = (
            amount: 1200.00,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            senderAccount: "1234",
            receiverAccount: "5678",
            referenceId: "MAKE001234",
            time: "16:45"
        )

        static let smallAmount = (
            amount: 50.00,
            senderName: "นายทดสอบ หนึ่ง",
            receiverName: "นายทดสอบ สอง",
            senderAccount: "9999",
            receiverAccount: "8888"
        )
    }
}
