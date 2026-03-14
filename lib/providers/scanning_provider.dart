import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/platform_service.dart';
import '../services/database_service.dart';
import '../models/payment_slip.dart';
import 'scanning_state.dart';

part 'scanning_provider.g.dart';

/// Helper to convert empty strings from iOS to null
String? _nonEmpty(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

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
      recipientName: _nonEmpty(slipData['receiverName']),
      senderName: _nonEmpty(slipData['senderName']),
      referenceId: _nonEmpty(slipData['referenceId']),
      senderAccount: _nonEmpty(slipData['senderAccount']),
      receiverAccount: _nonEmpty(slipData['receiverAccount']),
      transactionTime: _nonEmpty(slipData['time']),
    );
  }).toList();
}

const _englishMonths = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Parse Thai date - standalone function for isolate
DateTime? _parseThaiDateInIsolate(String dateStr) {
  try {
    final s = dateStr.trim();

    // YYYY-MM-DD (ISO, primary output from iOS normalizeToISODate)
    if (s.contains('-')) {
      final parts = s.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          // DD-MM-YYYY
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    }

    // DD/MM/YYYY (from iOS convertBuddhistToGregorian)
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 3 && parts[2].length == 4) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    }

    // "15 Mar 2024" or "5 March 2024" — English abbreviated/full month
    final spaced = s.split(RegExp(r'\s+'));
    if (spaced.length == 3) {
      final day = int.tryParse(spaced[0]);
      final month = _englishMonths[spaced[1].substring(0, 3).toLowerCase()];
      final year = int.tryParse(spaced[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
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
  Future<void> _handleScanComplete() async {
    try {
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
