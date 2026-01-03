import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import '../services/extraction_service.dart';
import '../services/cactus_service.dart';
import 'cactus_provider.dart';
import 'extraction_state.dart';

part 'extraction_provider.g.dart';

@Riverpod(keepAlive: true)
class ExtractionQueue extends _$ExtractionQueue {
  Timer? _processingTimer;
  bool _isProcessingItem = false;

  @override
  ExtractionQueueState build() {
    ref.onDispose(() {
      _processingTimer?.cancel();
    });

    // Load initial counts
    _loadCounts();

    return const ExtractionQueueState();
  }

  /// Load current queue counts from database
  Future<void> _loadCounts() async {
    try {
      final pending = await DatabaseService.countSlipsWithStatus('pending');
      final failed = await DatabaseService.countSlipsWithStatus('failed');
      state = state.copyWith(pendingCount: pending, failedCount: failed);
    } catch (e) {
      debugPrint('Error loading queue counts: $e');
    }
  }

  /// Start background processing - called after model is loaded
  void startBackgroundProcessing() {
    if (state.isProcessing) return;

    // Process queue every 2 seconds to avoid overwhelming device
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processNextInQueue();
    });
    state = state.copyWith(isProcessing: true);
    debugPrint('🤖 Background extraction started');
  }

  /// Stop background processing
  void stopBackgroundProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
    state = state.copyWith(isProcessing: false, currentSlipId: null);
    debugPrint('🤖 Background extraction stopped');
  }

  /// Process the next slip in the queue
  Future<void> _processNextInQueue() async {
    // Skip if already processing an item or model not loaded
    if (_isProcessingItem) return;

    final cactusState = ref.read(cactusProvider);
    if (!cactusState.isModelLoaded) return;

    _isProcessingItem = true;

    try {
      // Get next unprocessed slip from database
      final pendingSlips = await DatabaseService.getSlipsWithStatus('pending', limit: 1);
      if (pendingSlips.isEmpty) {
        _isProcessingItem = false;
        return;
      }

      final slip = pendingSlips.first;
      state = state.copyWith(currentSlipId: slip.id);

      debugPrint('🤖 Processing slip ${slip.id}...');

      // Mark as processing
      await DatabaseService.updateLLMStatus(slip.id!, 'processing');

      // Run extraction
      final result = await ExtractionService.extractFromText(slip.extractedText);
      debugPrint('🤖 Extracted: $result');

      // Update database with extracted data
      await DatabaseService.updateExtractedData(
        slip.id!,
        recipientName: result.recipientName,
        notes: result.notes,
        category: result.category,
      );

      // Mark as completed
      await DatabaseService.updateLLMStatus(slip.id!, 'completed');

      // Index in RAG
      await _indexInRAG(slip, result);

      // Update counts
      final pending = await DatabaseService.countSlipsWithStatus('pending');
      state = state.copyWith(
        processedCount: state.processedCount + 1,
        pendingCount: pending,
        currentSlipId: null,
      );

      debugPrint('🤖 Slip ${slip.id} processed successfully');
    } catch (e) {
      debugPrint('🤖 Extraction error: $e');

      // Mark as failed if we have a current slip
      if (state.currentSlipId != null) {
        await DatabaseService.updateLLMStatus(state.currentSlipId!, 'failed');
        final failed = await DatabaseService.countSlipsWithStatus('failed');
        final pending = await DatabaseService.countSlipsWithStatus('pending');
        state = state.copyWith(
          failedCount: failed,
          pendingCount: pending,
          currentSlipId: null,
        );
      }
    } finally {
      _isProcessingItem = false;
    }
  }

  /// Index a slip in RAG for semantic search
  Future<void> _indexInRAG(PaymentSlip slip, ExtractionResult result) async {
    try {
      // Create rich document for RAG indexing
      final content = '''
Payment of ${slip.amount} baht on ${slip.date.toIso8601String().split('T')[0]}.
${result.recipientName != null ? 'To: ${result.recipientName}' : ''}
${result.notes != null ? 'Notes: ${result.notes}' : ''}
${result.category != null ? 'Category: ${result.category}' : ''}
Original text: ${slip.extractedText.substring(0, slip.extractedText.length > 500 ? 500 : slip.extractedText.length)}
''';

      await CactusService.instance.storeInRAG(
        id: slip.id.toString(),
        content: content,
      );

      await DatabaseService.updateRAGIndexed(slip.id!, true);
      debugPrint('🤖 Slip ${slip.id} indexed in RAG');
    } catch (e) {
      debugPrint('🤖 RAG indexing error: $e');
      // Don't fail the whole extraction if RAG fails
    }
  }

  /// Manually trigger reprocessing of failed slips
  Future<void> retryFailed() async {
    await DatabaseService.resetFailedToStatus('pending');
    final pending = await DatabaseService.countSlipsWithStatus('pending');
    final failed = await DatabaseService.countSlipsWithStatus('failed');
    state = state.copyWith(pendingCount: pending, failedCount: failed);
    debugPrint('🤖 Reset ${state.failedCount} failed slips to pending');
  }

  /// Refresh queue counts from database
  Future<void> refreshCounts() async {
    await _loadCounts();
  }

  /// Process all pending slips immediately (for testing)
  Future<void> processAllPending() async {
    final cactusState = ref.read(cactusProvider);
    if (!cactusState.isModelLoaded) return;

    var pending = await DatabaseService.countSlipsWithStatus('pending');
    while (pending > 0) {
      await _processNextInQueue();
      pending = await DatabaseService.countSlipsWithStatus('pending');
    }
  }
}
