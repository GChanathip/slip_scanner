import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:avers/core/services/platform_service.dart';
import 'package:avers/core/database/database_service.dart';
import 'package:avers/core/utils/slip_conversion.dart';
import 'package:avers/features/scanning/providers/scanning_state.dart';

part 'scanning_provider.g.dart';

@Riverpod(keepAlive: true)
class Scanning extends _$Scanning {
  StreamSubscription? _progressSubscription;
  StreamSubscription? _partialResultsSubscription;
  final List<Future<void>> _pendingInserts = [];

  @override
  ScanningState build() {
    // Setup cleanup on dispose
    ref.onDispose(() {
      _progressSubscription?.cancel();
      _partialResultsSubscription?.cancel();
    });

    return const ScanningState();
  }

  /// Start scanning all photos
  /// Returns early if already scanning, completed, or has error
  /// Call reset() first if you want to force a new scan
  Future<void> startScanning() async {
    // Don't start if already scanning
    if (state.isScanning) return;

    // Don't start if previous scan completed (let user acknowledge first)
    if (state.isComplete) return;

    // Don't start if there's an error (let user acknowledge first)
    if (state.error != null) return;

    // Reset state and start scanning
    state = const ScanningState(isScanning: true);

    // Setup listeners BEFORE starting the scan
    _listenToProgress();
    _listenToPartialResults();

    // Small delay to ensure channels are set up
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Fetch already-processed asset IDs so iOS can skip them
      final processedIds = await DatabaseService.getProcessedAssetIds();

      // Fire and forget - don't await! iOS returns immediately
      // Completion is detected via progress stream (isComplete: true)
      await PlatformService.startScanning(processedAssetIds: processedIds);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isScanning: false);
    }
  }

  /// Cancel scanning
  Future<void> cancelScanning() async {
    try {
      await PlatformService.cancelScanning();
      _progressSubscription?.cancel();
      _partialResultsSubscription?.cancel();
      state = const ScanningState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel: $e');
    }
  }

  /// Listen to progress updates from platform
  void _listenToProgress() {
    _progressSubscription?.cancel();
    _progressSubscription = PlatformService.getProgressStream().listen(
      (progress) {
        final newTotal = progress['total'] ?? 0;
        final newProcessed = progress['processed'] ?? 0;
        final newSlipsFound = progress['slipsFound'] ?? 0;
        final newICloudSkipped = progress['iCloudSkipped'] ?? 0;
        final newIsComplete = progress['isComplete'] ?? false;

        // Only rebuild if values actually changed
        if (newTotal != state.totalPhotos ||
            newProcessed != state.processedPhotos ||
            newSlipsFound != state.slipsFound ||
            newICloudSkipped != state.iCloudSkipped ||
            newIsComplete != state.isComplete) {
          state = state.copyWith(
            totalPhotos: newTotal,
            processedPhotos: newProcessed,
            slipsFound: newSlipsFound,
            iCloudSkipped: newICloudSkipped,
            isComplete: newIsComplete,
          );
        }

        // Handle completion via stream instead of awaiting result
        if (newIsComplete && state.isScanning) {
          _handleScanComplete();
        }
      },
      onError: (error) {
        state = state.copyWith(error: error.toString(), isScanning: false);
      },
    );
  }

  /// Listen to partial results from platform.
  /// Each batch is immediately converted and inserted to DB — no state accumulation.
  void _listenToPartialResults() {
    _partialResultsSubscription?.cancel();
    _partialResultsSubscription = PlatformService.getPartialResultsStream().listen(
      (partialData) {
        final slips = partialData['slips'] as List<dynamic>? ?? [];
        if (slips.isNotEmpty) {
          final raw = slips.map((s) => Map<String, dynamic>.from(s)).toList();
          final future = _insertBatch(raw);
          _pendingInserts.add(future);
          future.whenComplete(() => _pendingInserts.remove(future));
        }
      },
      onError: (error) {
        // Silently handle partial results errors
      },
    );
  }

  Future<void> _insertBatch(List<Map<String, dynamic>> raw) async {
    final paymentSlips = await compute(convertSlipsInIsolate, raw);
    await DatabaseService.insertPaymentSlipsBatch(paymentSlips);
  }

  /// Handle scan completion — wait for all in-flight batch inserts, then finish.
  /// Cancels partial results listener first so no new inserts arrive during wait.
  Future<void> _handleScanComplete() async {
    try {
      _partialResultsSubscription?.cancel();
      _partialResultsSubscription = null;
      if (_pendingInserts.isNotEmpty) {
        await Future.wait(List.of(_pendingInserts));
      }
      _pendingInserts.clear();
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save results: $e', isScanning: false);
    }
  }

  /// Reset the scanning state (useful after viewing completion)
  void reset() {
    _progressSubscription?.cancel();
    _partialResultsSubscription?.cancel();
    _pendingInserts.clear();
    state = const ScanningState();
  }
}
