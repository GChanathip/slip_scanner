import Foundation

/// Dime slip OCR text fixtures.
/// Dime format: uses label-based extraction (จาก/ไปยัง) similar to SCB,
/// with x-#### account mask pattern.
enum DimeFixtures {

    // MARK: - OCR Text Samples

    /// Standard Dime transfer slip
    static let basicTransfer = """
Dime
โอนเงินสำเร็จ
จาก
นายสมชาย ใจดี
x-1234
ไปยัง
นางสาวสมหญิง รักดี
x-5678
จำนวนเงิน 500.00 บาท
12 ก.ค. 2567 - 13:00
รหัสอ้างอิง: DIME789012
"""

    // MARK: - Expected Values

    struct Expected {
        static let basicTransfer = (
            amount: 500.00,
            senderName: "นายสมชาย ใจดี",
            receiverName: "นางสาวสมหญิง รักดี",
            senderAccount: "1234",
            receiverAccount: "5678",
            referenceId: "DIME789012",
            time: "13:00"
        )
    }
}
