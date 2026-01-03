import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/platform_service.dart';
import '../services/database_service.dart';
import '../models/payment_slip.dart';
import 'scanning_state.dart';

part 'scanning_provider.g.dart';

/// Top-level function for isolate - must be outside class
List<PaymentSlip> convertSlipsInIsolate(List<dynamic> slips) {
  return slips.map((slip) {
    final slipData = Map<String, dynamic>.from(slip);

    // Parse date
    DateTime slipDate = DateTime.now();
    if (slipData['date'] != null && slipData['date'].toString().isNotEmpty) {
      slipDate = _parseThaiDateInIsolate(slipData['date']) ?? DateTime.now();
    }

    // Parse amount
    double amount = 0.0;
    if (slipData['amount'] != null) {
      if (slipData['amount'] is int) {
        amount = (slipData['amount'] as int).toDouble();
      } else if (slipData['amount'] is double) {
        amount = slipData['amount'] as double;
      } else {
        amount = double.tryParse(slipData['amount'].toString()) ?? 0.0;
      }
    }

    return PaymentSlip(
      imagePath: slipData['assetId'] ?? '',
      assetId: slipData['assetId'],
      amount: amount,
      date: slipDate,
      extractedText: slipData['text'] ?? '',
      createdAt: DateTime.now(),
    );
  }).toList();
}

/// Parse Thai date - standalone function for isolate
DateTime? _parseThaiDateInIsolate(String dateStr) {
  try {
    // Handle already converted dates (from iOS helper)
    if (dateStr.contains('/')) {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        // Check if it's already in DD/MM/YYYY format from iOS conversion
        if (parts[2].length == 4) {
          return DateTime(
            int.parse(parts[2]), // Year
            int.parse(parts[1]), // Month
            int.parse(parts[0]), // Day
          );
        }
      }
    }

    // Handle hyphen-separated dates
    if (dateStr.contains('-')) {
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // YYYY-MM-DD
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          // DD-MM-YYYY
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    }
  } catch (e) {
    // If parsing fails, return null to use current date
  }

  return null;
}

@Riverpod(keepAlive: true)
class Scanning extends _$Scanning {
  StreamSubscription? _progressSubscription;
  StreamSubscription? _partialResultsSubscription;

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
      // Fire and forget - don't await! iOS returns immediately
      // Completion is detected via progress stream (isComplete: true)
      await PlatformService.startScanning();
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
        final newIsComplete = progress['isComplete'] ?? false;

        // Only rebuild if values actually changed
        if (newTotal != state.totalPhotos ||
            newProcessed != state.processedPhotos ||
            newSlipsFound != state.slipsFound ||
            newIsComplete != state.isComplete) {
          state = state.copyWith(
            totalPhotos: newTotal,
            processedPhotos: newProcessed,
            slipsFound: newSlipsFound,
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

  /// Listen to partial results from platform
  void _listenToPartialResults() {
    _partialResultsSubscription?.cancel();
    _partialResultsSubscription = PlatformService.getPartialResultsStream().listen(
      (partialData) {
        final slips = partialData['slips'] as List<dynamic>? ?? [];
        if (slips.isNotEmpty) {
          final accumulated = List<Map<String, dynamic>>.from(state.accumulatedSlips);
          for (final slip in slips) {
            accumulated.add(Map<String, dynamic>.from(slip));
          }
          state = state.copyWith(accumulatedSlips: accumulated);
        }
      },
      onError: (error) {
        // Silently handle partial results errors
      },
    );
  }

  /// Handle scan completion - called when progress stream sends isComplete: true
  Future<void> _handleScanComplete() async {
    try {
      // Process accumulated slips from partial results in background isolate
      if (state.accumulatedSlips.isNotEmpty) {
        final paymentSlips = await compute(convertSlipsInIsolate, state.accumulatedSlips);
        await DatabaseService.insertPaymentSlipsBatch(paymentSlips);
      }

      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save results: $e', isScanning: false);
    }
  }

  /// Reset the scanning state (useful after viewing completion)
  void reset() {
    _progressSubscription?.cancel();
    _partialResultsSubscription?.cancel();
    state = const ScanningState();
  }
}
