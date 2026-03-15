import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:avers/features/budget/services/budget_alert_service.dart';
import 'package:avers/features/category/services/category_service.dart';
import 'package:avers/core/database/database_service.dart';
import 'package:avers/features/extraction/services/extraction_service.dart';
import 'package:avers/core/services/extraction_notifier.dart';
import 'package:avers/features/extraction/services/rag_queue_service.dart';
import 'package:avers/features/ai/providers/cactus_provider.dart';
import 'package:avers/features/extraction/providers/extraction_state.dart';

part 'extraction_provider.g.dart';

@Riverpod(keepAlive: true)
class ExtractionQueue extends _$ExtractionQueue {
  StreamSubscription<List<int>>? _newSlipsSubscription;
  bool _isRunning = false;
  int _pauseCount = 0;
  Completer<void>? _workAvailable;

  // Cached per-session for rule lookups and dynamic prompt generation.
  CategoryService? _categoryService;
  Set<String>? _cachedValidCategories;

  @override
  ExtractionQueueState build() {
    ref.onDispose(() {
      _isRunning = false;
      _newSlipsSubscription?.cancel();
      if (_workAvailable != null && !_workAvailable!.isCompleted) {
        _workAvailable!.complete();
      }
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

  /// Initialise CategoryService for rule overrides + dynamic prompts.
  /// Called fire-and-forget from [startBackgroundProcessing]; any error is
  /// non-fatal — rule overrides are simply skipped while null.
  Future<void> _initCategoryService() async {
    try {
      final db = await DatabaseService.database;
      _categoryService = CategoryService(db);
      _cachedValidCategories = await _categoryService!.getValidCategoryNames();
      debugPrint('✅ CategoryService ready for extraction');
    } catch (e) {
      debugPrint('⚠️ CategoryService init failed, rule overrides disabled: $e');
    }
  }

  /// Start event-driven background processing - called after model is loaded
  void startBackgroundProcessing() {
    if (_isRunning) return;
    _isRunning = true;
    state = state.copyWith(isProcessing: true);

    // Initialise CategoryService asynchronously (non-blocking).
    _initCategoryService();

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
    if (_workAvailable != null && !_workAvailable!.isCompleted) {
      _workAvailable!.complete();
    }
    _categoryService = null;
    _cachedValidCategories = null;
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
    if (_workAvailable != null && !_workAvailable!.isCompleted) {
      _workAvailable!.complete();
    }
    _workAvailable = null;
  }

  /// Main processing loop - event-driven, processes immediately when work available
  Future<void> _processingLoop() async {
    debugPrint('🔄 Processing loop started');

    while (_isRunning) {
      // Yield while paused (e.g., ChatScreen is active to avoid lock contention)
      while (_pauseCount > 0 && _isRunning) {
        _workAvailable = Completer<void>();
        await Future.any([
          _workAvailable!.future,
          Future.delayed(const Duration(milliseconds: 500)),
        ]);
      }
      if (!_isRunning) break;

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

      // Defense-in-depth: skip slips that have exceeded max retries
      if (slip.retryCount >= 3) {
        debugPrint('⏭ Slip ${slip.id} exceeded max retries (${slip.retryCount}), marking failed');
        await DatabaseService.updateLLMStatus(slip.id!, 'failed');
        final failed = await DatabaseService.countSlipsWithStatus('failed');
        final pending = await DatabaseService.countSlipsWithStatus('pending');
        state = state.copyWith(failedCount: failed, pendingCount: pending);
        return true; // Signal that we did work so the loop continues
      }

      state = state.copyWith(currentSlipId: slip.id);

      debugPrint('⚡ Processing slip ${slip.id}...');

      // Skip slips with empty OCR text (nothing useful to extract)
      if (slip.extractedText.trim().isEmpty) {
        debugPrint('⏭ Slip ${slip.id} has empty text, marking completed');
        await DatabaseService.updateLLMStatus(slip.id!, 'completed');
        final pending = await DatabaseService.countSlipsWithStatus('pending');
        state = state.copyWith(pendingCount: pending, currentSlipId: null);
        return true;
      }

      // Mark as processing
      await DatabaseService.updateLLMStatus(slip.id!, 'processing');

      // Run extraction (this is the main LLM work)
      final result = await ExtractionService.extractFromText(
        slip.extractedText,
        categoryService: _categoryService,
        cachedValidCategories: _cachedValidCategories,
      );
      debugPrint('⚡ Extracted: $result');

      // Update database with extracted data
      await DatabaseService.updateExtractedData(
        slip.id!,
        recipientName: result.recipientName,
        notes: result.notes,
        category: result.category,
        categorySource: result.categorySource,
      );

      // Mark as completed
      await DatabaseService.updateLLMStatus(slip.id!, 'completed');

      // Fire-and-forget RAG indexing (doesn't block next extraction!)
      RAGQueueService.instance.enqueue(slip, result);

      // Fire-and-forget budget threshold check
      BudgetAlertService.instance.checkThresholds();

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
