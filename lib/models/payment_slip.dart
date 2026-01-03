class PaymentSlip {
  final int? id;
  final String imagePath;
  final String? assetId;
  final double amount;
  final DateTime date;
  final String extractedText;
  final DateTime createdAt;

  // LLM-extracted fields
  final String? recipientName;
  final String? notes;
  final String? category;

  // Processing status for background queue
  final String llmProcessingStatus; // 'pending', 'processing', 'completed', 'failed'
  final bool ragIndexed;
  final DateTime? updatedAt;

  PaymentSlip({
    this.id,
    required this.imagePath,
    this.assetId,
    required this.amount,
    required this.date,
    required this.extractedText,
    required this.createdAt,
    this.recipientName,
    this.notes,
    this.category,
    this.llmProcessingStatus = 'pending',
    this.ragIndexed = false,
    this.updatedAt,
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
      'recipientName': recipientName,
      'notes': notes,
      'category': category,
      'llmProcessingStatus': llmProcessingStatus,
      'ragIndexed': ragIndexed ? 1 : 0,
      'updatedAt': updatedAt?.toIso8601String(),
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
      recipientName: map['recipientName'],
      notes: map['notes'],
      category: map['category'],
      llmProcessingStatus: map['llmProcessingStatus'] ?? 'pending',
      ragIndexed: (map['ragIndexed'] ?? 0) == 1,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  /// Create a copy with updated fields
  PaymentSlip copyWith({
    int? id,
    String? imagePath,
    String? assetId,
    double? amount,
    DateTime? date,
    String? extractedText,
    DateTime? createdAt,
    String? recipientName,
    String? notes,
    String? category,
    String? llmProcessingStatus,
    bool? ragIndexed,
    DateTime? updatedAt,
  }) {
    return PaymentSlip(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      assetId: assetId ?? this.assetId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      recipientName: recipientName ?? this.recipientName,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      llmProcessingStatus: llmProcessingStatus ?? this.llmProcessingStatus,
      ragIndexed: ragIndexed ?? this.ragIndexed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}