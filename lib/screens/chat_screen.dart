import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_state.dart';
import '../providers/cactus_provider.dart';
import '../providers/extraction_provider.dart';
import '../utils/ensure_model.dart';
import '../utils/formatters.dart';
import '../widgets/suggestion_chips_bar.dart';

@RoutePage()
class ChatScreen extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const ChatScreen({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  // Store notifier reference to avoid using ref in dispose
  ExtractionQueue? _extractionNotifier;

  @override
  void initState() {
    super.initState();
    // Set date range if provided; always load suggestion chips
    Future.microtask(() {
      final notifier = ref.read(chatProvider.notifier);
      if (widget.startDate != null || widget.endDate != null) {
        notifier.setDateRange(widget.startDate, widget.endDate);
      } else {
        notifier.loadSuggestionChips();
      }
    });
    // Ref-counted pause: extraction yields while chat is active (avoids LLM lock contention).
    // resumeExtraction() in dispose() is always called regardless of how the screen exits.
    Future.microtask(() {
      _extractionNotifier = ref.read(extractionQueueProvider.notifier);
      _extractionNotifier?.pauseExtraction();
    });
    // Ensure model is loaded
    _ensureModelLoaded();
  }

  Future<void> _ensureModelLoaded() async {
    await ensureModelLoaded(context, ref);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Always resume — ref-count ensures extraction only unpauses when all callers do
    _extractionNotifier?.resumeExtraction();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(message);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final chatState = ref.watch(chatProvider);
    final cactusState = ref.watch(cactusProvider);

    // Scroll to bottom when new messages arrive
    ref.listen(chatProvider.select((s) => s.messages.length), (_, _) {
      _scrollToBottom();
    });

    return FScaffold(
      header: FHeader.nested(
        title: const Text('AI Assistant'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
        suffixes: [
          if (chatState.hasMessages)
            FHeaderAction(
              icon: const Icon(FIcons.trash2),
              onPress: () => ref.read(chatProvider.notifier).clearMessages(),
            ),
        ],
      ),
      childPad: false,
      child: Column(
        children: [
          // Date range indicator
          if (chatState.startDate != null || chatState.endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colors.muted,
              child: Row(
                children: [
                  Icon(FIcons.calendar, size: 16, color: theme.colors.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    formatDateRange(chatState.startDate, chatState.endDate),
                    style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),

          // Model loading indicator
          if (!cactusState.isModelLoaded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (cactusState.isLoading) ...[
                    Text(cactusState.downloadStatus, style: theme.typography.sm),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: cactusState.isDownloading ? cactusState.downloadProgress : null),
                  ] else if (cactusState.error != null) ...[
                    FAlert(
                      variant: FAlertVariant.destructive,
                      title: const Text('Model Error'),
                      subtitle: Text(cactusState.error!),
                    ),
                  ] else ...[
                    const Text('Loading AI model...'),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(chatState.messages[index], theme);
                    },
                  ),
          ),

          // Suggestion chips bar — hidden while generating
          if (!chatState.isGenerating && chatState.suggestionChips.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colors.border)),
              ),
              child: SuggestionChipsBar(
                chips: chatState.suggestionChips,
                onChipTap: (chip) {
                  ref.read(chatProvider.notifier).sendMessage(chip.query);
                  _scrollToBottom();
                },
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: FTextField(
                      control: FTextFieldControl.managed(controller: _messageController),
                      hint: 'Ask about your expenses...',
                      onSubmit: (_) => _sendMessage(),
                      enabled: cactusState.isModelLoaded && !chatState.isGenerating,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: (cactusState.isModelLoaded && !chatState.isGenerating) ? _sendMessage : null,
                    child: chatState.isGenerating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(FIcons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FIcons.messageCircle, size: 64, color: theme.colors.mutedForeground),
          const SizedBox(height: 16),
          Text('Ask me about your expenses', style: theme.typography.xl),
          const SizedBox(height: 8),
          Text(
            'I can help you understand spending patterns,\nfind specific transactions, and give budget advice.',
            style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, FThemeData theme) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colors.primary,
              child: Icon(FIcons.bot, size: 18, color: theme.colors.primaryForeground),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? theme.colors.primary : theme.colors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content.isEmpty && message.isStreaming ? '...' : message.content,
                    style: theme.typography.base.copyWith(
                      color: isUser ? theme.colors.primaryForeground : theme.colors.foreground,
                    ),
                  ),
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            isUser ? theme.colors.primaryForeground : theme.colors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colors.muted,
              child: Icon(FIcons.user, size: 18, color: theme.colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }

}
