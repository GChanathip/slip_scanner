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
