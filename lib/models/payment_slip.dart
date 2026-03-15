class PaymentSlip {
  final int? id;
  final String imagePath;
  final String? assetId;
  final double amount;
  final DateTime date;
  final String extractedText;
  final DateTime createdAt;

  // OCR-extracted fields (multi-bank)
  final String? senderName;
  final String? referenceId;
  final String? senderAccount;
  final String? receiverAccount;
  final String? transactionTime;

  // LLM-extracted fields
  final String? recipientName;
  final String? notes;
  final String? category;

  // Processing status for background queue
  final String llmProcessingStatus; // 'pending', 'processing', 'completed', 'failed'
  final bool ragIndexed;
  final DateTime? updatedAt;
  final int retryCount;

  // Recurring transaction fields
  final bool isRecurring;
  final String? recurringFrequency; // 'weekly', 'monthly', 'custom', or null

  PaymentSlip({
    this.id,
    required this.imagePath,
    this.assetId,
    required this.amount,
    required this.date,
    required this.extractedText,
    required this.createdAt,
    this.senderName,
    this.referenceId,
    this.senderAccount,
    this.receiverAccount,
    this.transactionTime,
    this.recipientName,
    this.notes,
    this.category,
    this.llmProcessingStatus = 'pending',
    this.ragIndexed = false,
    this.updatedAt,
    this.retryCount = 0,
    this.isRecurring = false,
    this.recurringFrequency,
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
      'senderName': senderName,
      'referenceId': referenceId,
      'senderAccount': senderAccount,
      'receiverAccount': receiverAccount,
      'transactionTime': transactionTime,
      'recipientName': recipientName,
      'notes': notes,
      'category': category,
      'llmProcessingStatus': llmProcessingStatus,
      'ragIndexed': ragIndexed ? 1 : 0,
      'updatedAt': updatedAt?.toIso8601String(),
      'retryCount': retryCount,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringFrequency': recurringFrequency,
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
      senderName: map['senderName'],
      referenceId: map['referenceId'],
      senderAccount: map['senderAccount'],
      receiverAccount: map['receiverAccount'],
      transactionTime: map['transactionTime'],
      recipientName: map['recipientName'],
      notes: map['notes'],
      category: map['category'],
      llmProcessingStatus: map['llmProcessingStatus'] ?? 'pending',
      ragIndexed: (map['ragIndexed'] ?? 0) == 1,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      retryCount: map['retryCount'] as int? ?? 0,
      isRecurring: (map['isRecurring'] ?? 0) == 1,
      recurringFrequency: map['recurringFrequency'],
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
    String? senderName,
    String? referenceId,
    String? senderAccount,
    String? receiverAccount,
    String? transactionTime,
    String? recipientName,
    String? notes,
    String? category,
    String? llmProcessingStatus,
    bool? ragIndexed,
    DateTime? updatedAt,
    int? retryCount,
    bool? isRecurring,
    String? recurringFrequency,
  }) {
    return PaymentSlip(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      assetId: assetId ?? this.assetId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      referenceId: referenceId ?? this.referenceId,
      senderAccount: senderAccount ?? this.senderAccount,
      receiverAccount: receiverAccount ?? this.receiverAccount,
      transactionTime: transactionTime ?? this.transactionTime,
      recipientName: recipientName ?? this.recipientName,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      llmProcessingStatus: llmProcessingStatus ?? this.llmProcessingStatus,
      ragIndexed: ragIndexed ?? this.ragIndexed,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }
}
