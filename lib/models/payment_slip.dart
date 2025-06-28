class PaymentSlip {
  final int? id;
  final String imagePath;
  final String? assetId;
  final double amount;
  final DateTime date;
  final String extractedText;
  final DateTime createdAt;

  PaymentSlip({
    this.id,
    required this.imagePath,
    this.assetId,
    required this.amount,
    required this.date,
    required this.extractedText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'assetId': assetId,
      'amount': amount,
      'date': date.toIso8601String(),
      'extractedText': extractedText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentSlip.fromMap(Map<String, dynamic> map) {
    return PaymentSlip(
      id: map['id'],
      imagePath: map['imagePath'],
      assetId: map['assetId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      extractedText: map['extractedText'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}