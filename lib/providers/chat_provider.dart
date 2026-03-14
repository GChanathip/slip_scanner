import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/cactus_service.dart';
import '../services/chat_query_service.dart';
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

  /// Clear chat history
  void clearChat() {
    state = const ChatState();
  }

  /// Clear chat but keep date range
  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
