import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat('#,##0.00');
final _currencyFormatNoDecimal = NumberFormat('#,##0');

/// Formats amount as Thai Baht with thousand separators: ฿1,500.00
String formatCurrency(double amount) => '฿${_currencyFormat.format(amount)}';

/// Formats amount as Thai Baht without decimals: ฿1,500
String formatCurrencyCompact(double amount) => '฿${_currencyFormatNoDecimal.format(amount)}';

String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'All time';
  final startStr = start != null ? '${start.day}/${start.month}/${start.year}' : 'Beginning';
  final endStr = end != null ? '${end.day}/${end.month}/${end.year}' : 'Now';
  return '$startStr - $endStr';
}

String formatCategory(String category) {
  if (category.isEmpty) return 'Other';
  return category[0].toUpperCase() + category.substring(1);
}
