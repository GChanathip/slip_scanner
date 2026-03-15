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
  final String? categorySource; // 'ai' | 'rule' | null

  // Processing status for background queue
  final String llmProcessingStatus; // 'pending', 'processing', 'completed', 'failed'
  final bool ragIndexed;
  final DateTime? updatedAt;
  final int retryCount;

  // Bank detection fields
  final String? bankType; // BankType enum raw value (e.g. 'scb', 'kbank')
  final String? transRef; // PromptPay transaction reference (22-25 digit NITMX ID)

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
    this.categorySource,
    this.llmProcessingStatus = 'pending',
    this.ragIndexed = false,
    this.updatedAt,
    this.retryCount = 0,
    this.bankType,
    this.transRef,
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
      'categorySource': categorySource,
      'llmProcessingStatus': llmProcessingStatus,
      'ragIndexed': ragIndexed ? 1 : 0,
      'updatedAt': updatedAt?.toIso8601String(),
      'retryCount': retryCount,
      'bankType': bankType,
      'transRef': transRef,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringFrequency': recurringFrequency,
    };
  }

  factory PaymentSlip.fromMap(Map<String, dynamic> map) {
    return PaymentSlip(
      id: map['id'] as int?,
      imagePath: map['imagePath'] as String,
      assetId: map['assetId'] as String?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      extractedText: map['extractedText'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      senderName: map['senderName'] as String?,
      referenceId: map['referenceId'] as String?,
      senderAccount: map['senderAccount'] as String?,
      receiverAccount: map['receiverAccount'] as String?,
      transactionTime: map['transactionTime'] as String?,
      recipientName: map['recipientName'] as String?,
      notes: map['notes'] as String?,
      category: map['category'] as String?,
      categorySource: map['categorySource'] as String?,
      llmProcessingStatus: (map['llmProcessingStatus'] as String?) ?? 'pending',
      ragIndexed: ((map['ragIndexed'] as int?) ?? 0) == 1,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      retryCount: map['retryCount'] as int? ?? 0,
      bankType: map['bankType'] as String?,
      transRef: map['transRef'] as String?,
      isRecurring: ((map['isRecurring'] as int?) ?? 0) == 1,
      recurringFrequency: map['recurringFrequency'] as String?,
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
    String? categorySource,
    String? llmProcessingStatus,
    bool? ragIndexed,
    DateTime? updatedAt,
    int? retryCount,
    String? bankType,
    String? transRef,
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
      categorySource: categorySource ?? this.categorySource,
      llmProcessingStatus: llmProcessingStatus ?? this.llmProcessingStatus,
      ragIndexed: ragIndexed ?? this.ragIndexed,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      bankType: bankType ?? this.bankType,
      transRef: transRef ?? this.transRef,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }
}
