import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_state.freezed.dart';

@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String role, // 'user', 'assistant', 'system'
    required String content,
    required DateTime timestamp,
    @Default(false) bool isStreaming,
  }) = _ChatMessageModel;
}

@freezed
abstract class ChatState with _$ChatState {
  const ChatState._();

  const factory ChatState({
    @Default([]) List<ChatMessageModel> messages,
    @Default(false) bool isGenerating,
    DateTime? startDate,
    DateTime? endDate,
  }) = _ChatState;

  /// Whether the chat has any messages
  bool get hasMessages => messages.isNotEmpty;

  /// Get the last message
  ChatMessageModel? get lastMessage => messages.isNotEmpty ? messages.last : null;
}
