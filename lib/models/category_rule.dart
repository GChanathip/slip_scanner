class CategoryRule {
  final String recipientPattern;
  final String category;
  final String source;
  final String createdAt;

  const CategoryRule({
    required this.recipientPattern,
    required this.category,
    this.source = 'user',
    required this.createdAt,
  });

  factory CategoryRule.fromMap(Map<String, dynamic> map) => CategoryRule(
        recipientPattern: map['recipientPattern'] as String,
        category: map['category'] as String,
        source: map['source'] as String? ?? 'user',
        createdAt: map['createdAt'] as String,
      );

  Map<String, dynamic> toMap() => {
        'recipientPattern': recipientPattern,
        'category': category,
        'source': source,
        'createdAt': createdAt,
      };
}
