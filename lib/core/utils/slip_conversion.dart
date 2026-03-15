import 'package:avers/core/models/payment_slip.dart';

/// Convert empty strings from iOS platform channel to null.
/// iOS returns "" for missing optional fields instead of nil.
String? nonEmpty(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

const _englishMonths = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Parse date strings from iOS platform channel.
/// Supports: yyyy-MM-dd (ISO), DD/MM/YYYY (Buddhist conversion output),
/// "15 Mar 2024" / "5 March 2024" (English month).
DateTime? parseThaiDate(String dateStr) {
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

/// Convert platform channel slip data to PaymentSlip objects.
/// Must be a top-level function for `compute()` isolate compatibility.
List<PaymentSlip> convertSlipsInIsolate(List<dynamic> slips) {
  return slips.map((slip) {
    final slipData = Map<String, dynamic>.from(slip);

    // Parse date
    DateTime slipDate = DateTime.now();
    if (slipData['date'] != null && slipData['date'].toString().isNotEmpty) {
      slipDate = parseThaiDate(slipData['date']) ?? DateTime.now();
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
      recipientName: nonEmpty(slipData['receiverName']),
      senderName: nonEmpty(slipData['senderName']),
      referenceId: nonEmpty(slipData['referenceId']),
      senderAccount: nonEmpty(slipData['senderAccount']),
      receiverAccount: nonEmpty(slipData['receiverAccount']),
      transactionTime: nonEmpty(slipData['time']),
      bankType: nonEmpty(slipData['bankType']),
      transRef: nonEmpty(slipData['transRef']),
    );
  }).toList();
}
