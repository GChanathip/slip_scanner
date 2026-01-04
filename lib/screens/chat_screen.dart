import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_state.dart';
import '../providers/cactus_provider.dart';
import '../providers/extraction_provider.dart';

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
  bool _wasModelLoaded = false;

  @override
  void initState() {
    super.initState();
    // Set date range if provided
    if (widget.startDate != null || widget.endDate != null) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).setDateRange(widget.startDate, widget.endDate);
      });
    }
    // Pause background extraction while chatting to avoid lock contention
    // This makes the chat feel more responsive
    Future.microtask(() {
      _extractionNotifier = ref.read(extractionQueueProvider.notifier);
      _extractionNotifier?.stopBackgroundProcessing();
    });
    // Ensure model is loaded
    _ensureModelLoaded();
  }

  Future<void> _ensureModelLoaded() async {
    final cactusState = ref.read(cactusProvider);
    if (!cactusState.isModelLoaded && !cactusState.isLoading) {
      await ref.read(cactusProvider.notifier).downloadAndInitialize(cactusState.selectedModel);
      if (ref.read(cactusProvider).isModelLoaded) {
        _wasModelLoaded = true;
        // Don't start extraction here - we're in chat mode
      }
    } else if (cactusState.isModelLoaded) {
      _wasModelLoaded = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Resume background extraction when leaving chat
    // Use cached notifier reference to avoid using ref in dispose
    if (_wasModelLoaded && _extractionNotifier != null) {
      _extractionNotifier!.startBackgroundProcessing();
    }
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
    final theme = ShadTheme.of(context);
    final chatState = ref.watch(chatProvider);
    final cactusState = ref.watch(cactusProvider);

    // Scroll to bottom when new messages arrive
    ref.listen(chatProvider.select((s) => s.messages.length), (_, _) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        leading: ShadIconButton.ghost(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.foreground),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          if (chatState.hasMessages)
            ShadIconButton.ghost(
              icon: Icon(LucideIcons.trash2, color: theme.colorScheme.foreground),
              onPressed: () => ref.read(chatProvider.notifier).clearMessages(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          if (chatState.startDate != null || chatState.endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.muted,
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 16, color: theme.colorScheme.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateRange(chatState.startDate, chatState.endDate),
                    style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
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
                    Text(cactusState.downloadStatus, style: theme.textTheme.small),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: cactusState.isDownloading ? cactusState.downloadProgress : null),
                  ] else if (cactusState.error != null) ...[
                    ShadAlert.destructive(title: const Text('Model Error'), description: Text(cactusState.error!)),
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

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your expenses...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: cactusState.isModelLoaded && !chatState.isGenerating,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: (cactusState.isModelLoaded && !chatState.isGenerating) ? _sendMessage : null,
                    child: chatState.isGenerating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageCircle, size: 64, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 16),
          Text('Ask me about your expenses', style: theme.textTheme.h4),
          const SizedBox(height: 8),
          Text(
            'I can help you understand spending patterns,\nfind specific transactions, and give budget advice.',
            style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('What did I spend the most on?'),
              _buildSuggestionChip('Show my biggest expenses'),
              _buildSuggestionChip('Any budget advice?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, ShadThemeData theme) {
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
              backgroundColor: theme.colorScheme.primary,
              child: Icon(LucideIcons.bot, size: 18, color: theme.colorScheme.primaryForeground),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? theme.colorScheme.primary : theme.colorScheme.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content.isEmpty && message.isStreaming ? '...' : message.content,
                    style: theme.textTheme.p.copyWith(
                      color: isUser ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground,
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
                            isUser ? theme.colorScheme.primaryForeground : theme.colorScheme.primary,
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
              backgroundColor: theme.colorScheme.muted,
              child: Icon(LucideIcons.user, size: 18, color: theme.colorScheme.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'All time';
    final startStr = start != null ? '${start.day}/${start.month}/${start.year}' : 'Beginning';
    final endStr = end != null ? '${end.day}/${end.month}/${end.year}' : 'Now';
    return '$startStr - $endStr';
  }
}
