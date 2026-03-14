import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/database_service.dart';
import '../services/extraction_service.dart';
import '../services/extraction_notifier.dart';
import '../services/rag_queue_service.dart';
import 'cactus_provider.dart';
import 'extraction_state.dart';

part 'extraction_provider.g.dart';

@Riverpod(keepAlive: true)
class ExtractionQueue extends _$ExtractionQueue {
  StreamSubscription<List<int>>? _newSlipsSubscription;
  bool _isRunning = false;
  int _pauseCount = 0;
  Completer<void>? _workAvailable;

  @override
  ExtractionQueueState build() {
    ref.onDispose(() {
      _isRunning = false;
      _newSlipsSubscription?.cancel();
      _workAvailable?.complete();
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
      final ragPending = RAGQueueService.instance.pendingCount;
      state = state.copyWith(
        pendingCount: pending,
        failedCount: failed,
        ragQueueCount: ragPending,
      );
    } catch (e) {
      debugPrint('Error loading queue counts: $e');
    }
  }

  /// Start event-driven background processing - called after model is loaded
  void startBackgroundProcessing() {
    if (_isRunning) return;
    _isRunning = true;
    state = state.copyWith(isProcessing: true);

    // Listen for new slips (event-driven - no polling delay!)
    _newSlipsSubscription = ExtractionNotifier.instance.onNewSlips.listen((_) {
      debugPrint('🚀 New slips notification received - signaling work available');
      _signalWorkAvailable();
    });

    // Start the continuous processing loop
    _processingLoop();
    debugPrint('🚀 Background extraction started (event-driven)');
  }

  /// Stop background processing
  void stopBackgroundProcessing() {
    _isRunning = false;
    _pauseCount = 0;
    _newSlipsSubscription?.cancel();
    _newSlipsSubscription = null;
    _workAvailable?.complete();
    state = state.copyWith(isProcessing: false, currentSlipId: null);
    debugPrint('🛑 Background extraction stopped');
  }

  /// Pause extraction (ref-counted). Extraction resumes when all callers
  /// call resumeExtraction(). Safe to call multiple times — each pause()
  /// must be paired with exactly one resume().
  void pauseExtraction() {
    _pauseCount++;
    debugPrint('⏸ Extraction paused (count: $_pauseCount)');
  }

  /// Resume extraction. Decrements pause ref-count; extraction resumes
  /// when count reaches zero. Idempotent if called without a prior pause.
  void resumeExtraction() {
    if (_pauseCount > 0) {
      _pauseCount--;
      if (_pauseCount == 0) {
        _signalWorkAvailable();
        debugPrint('▶️ Extraction resumed');
      }
    }
  }

  /// Signal that work is available (wakes up the processing loop)
  void _signalWorkAvailable() {
    _workAvailable?.complete();
    _workAvailable = null;
  }

  /// Main processing loop - event-driven, processes immediately when work available
  Future<void> _processingLoop() async {
    debugPrint('🔄 Processing loop started');

    while (_isRunning) {
      // Yield while paused (e.g., ChatScreen is active to avoid lock contention)
      if (_pauseCount > 0) {
        _workAvailable = Completer<void>();
        await Future.any([
          _workAvailable!.future,
          Future.delayed(const Duration(milliseconds: 500)),
        ]);
        continue;
      }

      final cactusState = ref.read(cactusProvider);
      if (!cactusState.isModelLoaded) {
        // Wait for model to load
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      // Try to process extraction queue first (higher priority)
      final processed = await _processNextSlip();

      if (!processed) {
        // No extraction work - try RAG queue (lower priority, when LLM idle)
        final ragProcessed = await RAGQueueService.instance.processOne();

        if (ragProcessed) {
          // Update RAG queue count
          state = state.copyWith(ragQueueCount: RAGQueueService.instance.pendingCount);
        } else {
          // No work at all - wait for signal or short timeout
          _workAvailable = Completer<void>();
          await Future.any([
            _workAvailable!.future,
            Future.delayed(const Duration(seconds: 30)),
          ]);
        }
      }
    }

    debugPrint('🔄 Processing loop ended');
  }

  /// Process one slip from the extraction queue. Returns true if a slip was processed.
  Future<bool> _processNextSlip() async {
    try {
      final pendingSlips = await DatabaseService.getSlipsWithStatus('pending', limit: 1);
      if (pendingSlips.isEmpty) return false;

      final slip = pendingSlips.first;
      state = state.copyWith(currentSlipId: slip.id);

      debugPrint('⚡ Processing slip ${slip.id}...');

      // Mark as processing
      await DatabaseService.updateLLMStatus(slip.id!, 'processing');

      // Run extraction (this is the main LLM work)
      final result = await ExtractionService.extractFromText(slip.extractedText);
      debugPrint('⚡ Extracted: $result');

      // Update database with extracted data
      await DatabaseService.updateExtractedData(
        slip.id!,
        recipientName: result.recipientName,
        notes: result.notes,
        category: result.category,
      );

      // Mark as completed
      await DatabaseService.updateLLMStatus(slip.id!, 'completed');

      // Fire-and-forget RAG indexing (doesn't block next extraction!)
      RAGQueueService.instance.enqueue(slip, result);

      // Update counts
      final pending = await DatabaseService.countSlipsWithStatus('pending');
      state = state.copyWith(
        processedCount: state.processedCount + 1,
        pendingCount: pending,
        ragQueueCount: RAGQueueService.instance.pendingCount,
        currentSlipId: null,
      );

      ExtractionNotifier.instance.notifyExtractionComplete(slip.id!);
      debugPrint('✅ Slip ${slip.id} extracted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Extraction error: $e');

      // Mark as failed if we have a current slip
      if (state.currentSlipId != null) {
        await DatabaseService.incrementRetryCount(state.currentSlipId!);
        await DatabaseService.updateLLMStatus(state.currentSlipId!, 'failed');
        final failed = await DatabaseService.countSlipsWithStatus('failed');
        final pending = await DatabaseService.countSlipsWithStatus('pending');
        state = state.copyWith(
          failedCount: failed,
          pendingCount: pending,
          currentSlipId: null,
        );
      }
      return true; // Still counts as "processed attempt" to avoid infinite retry loop
    }
  }

  /// Manually trigger reprocessing of failed slips
  Future<void> retryFailed() async {
    await DatabaseService.resetFailedToStatus('pending');
    await _loadCounts();
    _signalWorkAvailable(); // Wake up the loop immediately
    debugPrint('🔄 Reset failed slips to pending');
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
    while (pending > 0 && _isRunning) {
      await _processNextSlip();
      pending = await DatabaseService.countSlipsWithStatus('pending');
    }
  }
}
