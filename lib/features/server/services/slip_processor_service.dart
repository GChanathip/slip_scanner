import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:avers/core/models/payment_slip.dart';
import 'package:avers/core/utils/slip_conversion.dart';
import 'package:avers/core/database/database_service.dart';
import 'package:avers/core/services/platform_service.dart';

/// Orchestrates the image → OCR → DB pipeline for server-side slip processing.
/// Used by the LINE webhook handler when an image is received.
class SlipProcessorService {
  /// Process an image received from LINE.
  /// Returns a formatted summary string for the LINE reply, or an error message.
  static Future<String> processLineImage(Uint8List imageData) async {
    // 1. Run OCR via platform channel (Vision Framework on macOS)
    final ocrResult = await PlatformService.processImageData(imageData);
    if (ocrResult == null) {
      return 'Could not detect a payment slip in this image. Please send a clear photo of a Thai banking slip.';
    }

    // 2. Convert OCR result to PaymentSlip
    final slips = convertSlipsInIsolate([ocrResult]);
    if (slips.isEmpty) {
      return 'Could not extract payment data from this image.';
    }

    // 3. Insert to database (triggers ExtractionNotifier for LLM processing)
    await DatabaseService.insertPaymentSlipsBatch(slips);

    // 4. Format immediate OCR result for LINE reply
    // (LLM extraction runs async in background via ExtractionQueue)
    final slip = slips.first;
    return _formatSlipSummary(slip);
  }

  /// Format a slip for LINE reply message.
  static String _formatSlipSummary(PaymentSlip slip) {
    final lines = <String>['[Receipt Scanned]'];

    lines.add('Amount: ${_formatAmount(slip.amount)} baht');

    final dateStr = '${slip.date.year}-${slip.date.month.toString().padLeft(2, '0')}-${slip.date.day.toString().padLeft(2, '0')}';
    lines.add('Date: $dateStr');

    if (slip.transactionTime != null) {
      lines.add('Time: ${slip.transactionTime}');
    }
    if (slip.senderName != null) {
      lines.add('From: ${slip.senderName}');
    }
    if (slip.recipientName != null) {
      lines.add('To: ${slip.recipientName}');
    }
    if (slip.referenceId != null) {
      lines.add('Ref: ${slip.referenceId}');
    }

    return lines.join('\n');
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble() && amount == amount.toInt().toDouble()) {
      final whole = amount.toInt().toString();
      // Add thousands separator
      final formatted = whole.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '฿$formatted';
    }
    final formatted = amount.toStringAsFixed(2);
    // Add thousands separator
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '฿$intPart.${parts[1]}';
  }
}
