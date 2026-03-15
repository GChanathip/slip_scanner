import 'package:avers/features/ai/services/cactus_service.dart';
import 'package:avers/features/analysis/providers/analysis_provider.dart';
import 'package:avers/features/analysis/services/monthly_summary_service.dart';
import 'package:avers/features/budget/providers/budget_provider.dart';
import 'package:avers/features/chat/providers/chat_state.dart';
import 'package:avers/features/chat/services/chat_query_service.dart';
import 'package:avers/features/chat/services/suggestion_chip_service.dart';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  @override
  ChatState build() => const ChatState();

  /// Load contextual suggestion chips from analysis + budget state.
  void loadSuggestionChips() {
    final analysis = ref.read(analysisProvider);
    final budget = ref.read(budgetProvider);
    final chips = SuggestionChipService.generate(analysis, budget);
    state = state.copyWith(suggestionChips: chips);
  }

  /// Set date range filter for analysis
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    loadSuggestionChips();
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
      final stats = await ChatQueryService.getStatsForDateRange(
        startDate: state.startDate,
        endDate: state.endDate,
      );

      // Build system prompt with context
      final systemPrompt = ChatQueryService.buildSystemPrompt(
        stats: stats,
        ragContext: ragContext,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      // Limit message history to avoid exceeding context window
      final recentMessages = state.messages.length > 20
          ? state.messages.sublist(state.messages.length - 20)
          : state.messages;

      // Create message list for LLM
      final llmMessages = [
        ChatMessage(content: systemPrompt, role: 'system'),
        ...recentMessages.map((m) => ChatMessage(content: m.content, role: m.role)),
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

  /// Inject last month's summary as the first assistant message, once per month.
  Future<void> injectSummaryIfNeeded() async {
    if (state.hasMessages) return;
    try {
      final now = DateTime.now();
      final prev = now.month == 1 ? DateTime(now.year - 1, 12) : DateTime(now.year, now.month - 1);
      final monthKey = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
      final summary = await MonthlySummaryService.instance.getSummary(monthKey);
      if (summary == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_summary_injected_$monthKey';
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);

      state = state.copyWith(
        messages: [
          ChatMessageModel(
            role: 'assistant',
            content: summary.narrative,
            timestamp: DateTime.now(),
          ),
        ],
      );
    } catch (e) {
      debugPrint('ChatProvider: summary injection failed: $e');
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
