import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';

import 'cactus_service.dart';
import 'database_service.dart';

/// Handles text queries for the LINE bot (and ChatProvider).
/// Extracted from ChatProvider so it can be used without Riverpod widget context.
class ChatQueryService {
  /// Build the system prompt with stats and RAG context.
  static String buildSystemPrompt({
    required String stats,
    required String ragContext,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final dateRangeStr = startDate != null && endDate != null
        ? '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}'
        : 'all time';

    return '''You are a helpful expense tracking assistant for a Thai banking slip scanner app.
You help users understand their spending patterns and provide financial insights.

Current date range filter: $dateRangeStr

$stats

${ragContext.isNotEmpty ? 'Relevant expense records:\n$ragContext' : ''}

Guidelines:
- Be concise and helpful
- Format currency amounts clearly (e.g., 1,234.56 baht)
- Provide actionable insights when appropriate
- If asked about specific transactions, reference the data above
- For budget advice, be practical and non-judgmental
- Answer in the same language the user uses (Thai or English)''';
  }

  /// Get summary statistics for a date range.
  static Future<String> getStatsForDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final slips = await DatabaseService.getPaymentSlipsInRange(
        startDate ?? DateTime(2000),
        endDate ?? DateTime.now(),
      );

      if (slips.isEmpty) {
        return 'Summary: No expense records found for this period.';
      }

      final total = slips.fold<double>(0, (sum, s) => sum + s.amount);
      final count = slips.length;
      final avg = count > 0 ? total / count : 0;

      // Group by category
      final byCategory = <String, double>{};
      for (final slip in slips) {
        final cat = slip.category ?? 'uncategorized';
        byCategory[cat] = (byCategory[cat] ?? 0) + slip.amount;
      }

      // Sort categories by amount
      final sortedCategories = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final categoryStr = sortedCategories
          .take(5)
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} baht')
          .join(', ');

      return '''Summary statistics for this period:
- Total spending: ${total.toStringAsFixed(2)} baht
- Transaction count: $count
- Average transaction: ${avg.toStringAsFixed(2)} baht
- Top categories: $categoryStr''';
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return 'Summary: Unable to load statistics.';
    }
  }

  /// Process a text query and return the LLM response.
  /// Used by LINE bot for text messages.
  static Future<String> processQuery(String userMessage) async {
    // 1. Search RAG for relevant context
    String ragContext = '';
    try {
      final ragResults =
          await CactusService.instance.searchRAG(userMessage, limit: 5);
      if (ragResults.isNotEmpty) {
        ragContext = ragResults.map((r) => r.chunk.content).join('\n---\n');
      }
    } catch (e) {
      debugPrint('RAG search failed: $e');
    }

    // 2. Get stats
    final stats = await getStatsForDateRange();

    // 3. Build system prompt
    final systemPrompt = buildSystemPrompt(stats: stats, ragContext: ragContext);

    // 4. Generate completion (non-streaming for LINE)
    final messages = [
      ChatMessage(content: systemPrompt, role: 'system'),
      ChatMessage(content: userMessage, role: 'user'),
    ];

    final result = await CactusService.instance.generateCompletion(messages);
    return result.response;
  }
}
