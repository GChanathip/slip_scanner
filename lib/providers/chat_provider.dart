import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/cactus_service.dart';
import '../services/database_service.dart';
import 'chat_state.dart';

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  @override
  ChatState build() => const ChatState();

  /// Set date range filter for analysis
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String userMessage) async {
    if (state.isGenerating) return;
    if (userMessage.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessageModel(
      role: 'user',
      content: userMessage.trim(),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isGenerating: true,
    );

    try {
      // Search RAG for relevant context
      String ragContext = '';
      try {
        final ragResults = await CactusService.instance.searchRAG(userMessage, limit: 5);
        if (ragResults.isNotEmpty) {
          ragContext = ragResults.map((r) => r.chunk.content).join('\n---\n');
        }
      } catch (e) {
        debugPrint('RAG search failed: $e');
      }

      // Get summary stats for date range
      final stats = await _getStatsForDateRange();

      // Build system prompt with context
      final systemPrompt = _buildSystemPrompt(stats, ragContext);

      // Create message list for LLM
      final llmMessages = [
        ChatMessage(content: systemPrompt, role: 'system'),
        ...state.messages.map((m) => ChatMessage(content: m.content, role: m.role)),
      ];

      // Stream response
      final streamResult = await CactusService.instance.generateCompletionStream(llmMessages);

      // Add streaming assistant message
      final contentBuffer = StringBuffer();
      final assistantMsg = ChatMessageModel(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      state = state.copyWith(messages: [...state.messages, assistantMsg]);

      // Batch state updates to every 100ms instead of per-token
      var lastUpdateMs = DateTime.now().millisecondsSinceEpoch;
      await for (final chunk in streamResult.stream) {
        contentBuffer.write(chunk);
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - lastUpdateMs >= 100) {
          final updatedMsg = assistantMsg.copyWith(content: contentBuffer.toString());
          state = state.copyWith(
            messages: [...state.messages.sublist(0, state.messages.length - 1), updatedMsg],
          );
          lastUpdateMs = nowMs;
        }
      }

      // Finalize message — always flush the buffer
      final finalMsg = assistantMsg.copyWith(
        content: contentBuffer.toString(),
        isStreaming: false,
      );
      state = state.copyWith(
        messages: [...state.messages.sublist(0, state.messages.length - 1), finalMsg],
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      // Add error message
      final errorMsg = ChatMessageModel(
        role: 'assistant',
        content: 'Sorry, I encountered an error: $e',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMsg]);
    }
  }

  /// Build system prompt with context
  String _buildSystemPrompt(String stats, String ragContext) {
    final dateRangeStr = state.startDate != null && state.endDate != null
        ? '${state.startDate!.toIso8601String().split('T')[0]} to ${state.endDate!.toIso8601String().split('T')[0]}'
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

  /// Get summary statistics for the selected date range
  Future<String> _getStatsForDateRange() async {
    try {
      final slips = await DatabaseService.getPaymentSlipsInRange(
        state.startDate ?? DateTime(2000),
        state.endDate ?? DateTime.now(),
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

  /// Clear chat history
  void clearChat() {
    state = const ChatState();
  }

  /// Clear chat but keep date range
  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
