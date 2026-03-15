import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';

import 'cactus_service.dart';
import 'database_service.dart';

const _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

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
- Reference the day-of-week patterns, spending velocity, and recipient data above to give specific advice
- If asked about specific transactions, reference the data above
- For budget advice, be practical and non-judgmental
- Answer in the same language the user uses (Thai or English)''';
  }

  /// Get summary statistics for a date range, enriched with analytics.
  static Future<String> getStatsForDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final effectiveStart = startDate ?? DateTime(2000);
      final effectiveEnd = endDate ?? DateTime.now();

      final slips = await DatabaseService.getPaymentSlipsInRange(effectiveStart, effectiveEnd);

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
      final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final categoryStr = sortedCategories.take(5).map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} baht').join(', ');

      final buffer = StringBuffer();
      buffer.writeln('Summary statistics for this period:');
      buffer.writeln('- Total spending: ${total.toStringAsFixed(2)} baht');
      buffer.writeln('- Transaction count: $count');
      buffer.writeln('- Average transaction: ${avg.toStringAsFixed(2)} baht');
      buffer.writeln('- Top categories: $categoryStr');

      // Day-of-week patterns
      try {
        final dowTotals = await DatabaseService.getDayOfWeekTotals(effectiveStart, effectiveEnd);
        if (dowTotals.isNotEmpty) {
          final dowAvg = dowTotals.values.reduce((a, b) => a + b) / dowTotals.length;
          final weekdayTotal = [1, 2, 3, 4, 5].fold(0.0, (s, d) => s + (dowTotals[d] ?? 0));
          final weekendTotal = [0, 6].fold(0.0, (s, d) => s + (dowTotals[d] ?? 0));
          final topDay = dowTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
          buffer.writeln('\nDay-of-week spending patterns:');
          buffer.writeln('- ${dowTotals.entries.map((e) => '${_dayNames[e.key]}: ${e.value.toStringAsFixed(0)} baht').join(', ')}');
          buffer.writeln('- Weekday total: ${weekdayTotal.toStringAsFixed(0)} baht, Weekend total: ${weekendTotal.toStringAsFixed(0)} baht');
          if (weekdayTotal > 0) {
            final weekendRatio = weekendTotal / (weekendTotal + weekdayTotal) * 100;
            buffer.writeln('- Weekend accounts for ${weekendRatio.toStringAsFixed(1)}% of spending');
          }
          buffer.writeln('- Highest spending day: ${_dayNames[topDay.key]} (${((topDay.value / dowAvg - 1) * 100).toStringAsFixed(0)}% above average)');
        }
      } catch (e) {
        debugPrint('Day-of-week stats failed: $e');
      }

      // Spending velocity (current month vs. last month projection)
      try {
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        final dayOfMonth = now.day;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        final currentTotal = await DatabaseService.getTotalForPeriod(currentMonthStart, now);
        final lastTotal = await DatabaseService.getTotalForPeriod(lastMonthStart, lastMonthEnd);

        if (currentTotal > 0 || lastTotal > 0) {
          final projectedTotal = dayOfMonth > 0 ? (currentTotal / dayOfMonth) * daysInMonth : 0.0;
          buffer.writeln('\nSpending velocity:');
          buffer.writeln('- Current month so far (day $dayOfMonth/$daysInMonth): ${currentTotal.toStringAsFixed(0)} baht');
          buffer.writeln('- Projected month total: ${projectedTotal.toStringAsFixed(0)} baht');
          buffer.writeln('- Last month total: ${lastTotal.toStringAsFixed(0)} baht');
          if (lastTotal > 0) {
            final diff = projectedTotal - lastTotal;
            final pct = (diff / lastTotal * 100).toStringAsFixed(0);
            buffer.writeln('- Projection vs. last month: ${diff > 0 ? '+' : ''}${diff.toStringAsFixed(0)} baht (${diff > 0 ? '+' : ''}$pct%)');
          }
        }
      } catch (e) {
        debugPrint('Spending velocity stats failed: $e');
      }

      // Top recipients
      try {
        final topRecipients = await DatabaseService.getTopRecipients(effectiveStart, effectiveEnd, limit: 5);
        if (topRecipients.isNotEmpty) {
          final topTotal = topRecipients.values.fold(0.0, (s, v) => s + v);
          final topPct = total > 0 ? (topTotal / total * 100).toStringAsFixed(1) : '0';
          buffer.writeln('\nTop recipients:');
          buffer.writeln('- ${topRecipients.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)} baht').join(', ')}');
          buffer.writeln('- Top ${topRecipients.length} recipients account for $topPct% of total spending');
        }
      } catch (e) {
        debugPrint('Top recipients stats failed: $e');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return 'Summary: Unable to load statistics.';
    }
  }

  /// Process a text query and return the LLM response.
  /// Used by LINE bot for text messages.
  static Future<String> processQuery(String userMessage) async {
    if (!CactusService.instance.isLoaded) {
      return 'The AI model is not loaded yet. OCR scanning still works, but text queries are unavailable. Please load the model from the server dashboard first.';
    }

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
