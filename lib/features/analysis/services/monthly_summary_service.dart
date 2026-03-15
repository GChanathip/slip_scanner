import 'package:avers/core/database/database_service.dart';
import 'package:avers/features/ai/services/cactus_service.dart';
import 'package:avers/features/analysis/models/monthly_summary.dart';
import 'package:avers/features/budget/services/budget_service.dart';
import 'package:cactus/models/types.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastSummaryMonth = 'last_summary_month';
const _kSummaryPrefix = 'monthly_summaries.';

/// Service that auto-generates natural language monthly spending reports.
///
/// Reports are generated once per month on first app open after month end and
/// cached in SharedPreferences so subsequent reads are instant.
class MonthlySummaryService {
  static MonthlySummaryService? _instance;
  static MonthlySummaryService get instance =>
      _instance ??= MonthlySummaryService._();
  MonthlySummaryService._();

  /// Check whether a summary for the previous month is missing and generate it.
  ///
  /// Returns the newly generated [MonthlySummary] if generation happened, the
  /// cached summary if it already exists, or null if there is no data yet.
  Future<MonthlySummary?> checkAndGenerate() async {
    final now = DateTime.now();
    final previousMonth = _previousMonth(now);
    final previousMonthKey = _monthKey(previousMonth);

    final prefs = await SharedPreferences.getInstance();
    final lastSummaryMonth = prefs.getString(_kLastSummaryMonth);

    // Generate if we haven't summarised the previous calendar month yet.
    if (lastSummaryMonth == null ||
        lastSummaryMonth.compareTo(previousMonthKey) < 0) {
      return generateSummary(previousMonthKey);
    }

    // Summary already generated — return from cache.
    return getSummary(previousMonthKey);
  }

  /// Generate (or regenerate) a summary for [monthKey] (format "YYYY-MM").
  ///
  /// Queries the database for aggregates, calls the LLM for a narrative, then
  /// persists the result to SharedPreferences.
  ///
  /// Returns null when there is no spending data for the requested month.
  Future<MonthlySummary?> generateSummary(String monthKey) async {
    final monthStart = _monthStart(monthKey);
    final monthEnd = _monthEnd(monthKey);

    // Total spent for the month.
    final totalSpent =
        await DatabaseService.getTotalForPeriod(monthStart, monthEnd);

    // Nothing to summarise yet (first month of usage or genuinely empty).
    if (totalSpent == 0) return null;

    // Monthly budget target (0 means not configured).
    final budgetTarget = await BudgetService.getOverallBudget();

    // Previous-previous month total for month-over-month comparison.
    final prevMonth = _previousMonth(monthStart);
    final prevMonthKey = _monthKey(prevMonth);
    final previousMonthSpent = await DatabaseService.getTotalForPeriod(
      _monthStart(prevMonthKey),
      _monthEnd(prevMonthKey),
    );

    // Category breakdown — getCategoryTrend returns {month -> {cat -> total}}.
    // For a single-month query there is at most one entry in the outer map.
    final categoryTrend =
        await DatabaseService.getCategoryTrend(monthStart, monthEnd);
    final categoryBreakdown = categoryTrend.values.isNotEmpty
        ? Map<String, double>.from(categoryTrend.values.first)
        : <String, double>{};

    // Top 5 recipients by total.
    final topRecipients = await DatabaseService.getTopRecipients(
      monthStart,
      monthEnd,
      limit: 5,
    );

    // Generate LLM narrative (falls back to plain stats if model not loaded).
    final narrative = await _generateNarrative(
      monthKey: monthKey,
      totalSpent: totalSpent,
      budgetTarget: budgetTarget,
      previousMonthSpent: previousMonthSpent,
      categoryBreakdown: categoryBreakdown,
      topRecipients: topRecipients,
    );

    final summary = MonthlySummary(
      month: monthKey,
      totalSpent: totalSpent,
      budgetTarget: budgetTarget,
      previousMonthSpent: previousMonthSpent,
      categoryBreakdown: categoryBreakdown,
      topRecipients: topRecipients,
      narrative: narrative,
      generatedAt: DateTime.now(),
    );

    // Persist to SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kSummaryPrefix$monthKey', summary.toJsonString());
    await prefs.setString(_kLastSummaryMonth, monthKey);

    return summary;
  }

  /// Retrieve the cached summary for [monthKey], or null if not yet generated.
  Future<MonthlySummary?> getSummary(String monthKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kSummaryPrefix$monthKey');
    if (raw == null) return null;
    try {
      return MonthlySummary.fromJsonString(raw);
    } catch (e) {
      debugPrint('MonthlySummaryService: failed to decode cached summary: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // LLM narrative
  // ---------------------------------------------------------------------------

  Future<String> _generateNarrative({
    required String monthKey,
    required double totalSpent,
    required double budgetTarget,
    required double previousMonthSpent,
    required Map<String, double> categoryBreakdown,
    required Map<String, double> topRecipients,
  }) async {
    if (!CactusService.instance.isLoaded) {
      return _fallbackNarrative(
        monthKey: monthKey,
        totalSpent: totalSpent,
        budgetTarget: budgetTarget,
        previousMonthSpent: previousMonthSpent,
      );
    }

    final topCats = (categoryBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '${e.key}: ฿${e.value.toStringAsFixed(0)}')
        .join(', ');

    final topRecs = topRecipients.entries
        .take(3)
        .map((e) => '${e.key}: ฿${e.value.toStringAsFixed(0)}')
        .join(', ');

    final budgetLine = budgetTarget > 0
        ? '฿${budgetTarget.toStringAsFixed(0)}'
        : 'not set';

    final notablePatterns = _buildPatterns(
      totalSpent: totalSpent,
      budgetTarget: budgetTarget,
      previousMonthSpent: previousMonthSpent,
    );

    final prompt =
        'Generate a concise monthly spending summary.\n'
        'Month: $monthKey\n'
        'Total spent: ฿${totalSpent.toStringAsFixed(0)} baht | '
        'Budget: $budgetLine baht | '
        'Last month: ฿${previousMonthSpent.toStringAsFixed(0)} baht\n'
        'Top categories: $topCats\n'
        'Top recipients: $topRecs\n'
        'Notable patterns: $notablePatterns\n\n'
        'Format: 3-4 sentences, conversational, actionable. '
        'Mix Thai and English naturally.';

    try {
      final result = await CactusService.instance.generateCompletion([
        ChatMessage(content: prompt, role: 'user'),
      ]);
      if (result.success) return result.response.trim();
      debugPrint('MonthlySummaryService: LLM returned failure: ${result.response}');
    } catch (e) {
      debugPrint('MonthlySummaryService: LLM narrative failed: $e');
    }

    return _fallbackNarrative(
      monthKey: monthKey,
      totalSpent: totalSpent,
      budgetTarget: budgetTarget,
      previousMonthSpent: previousMonthSpent,
    );
  }

  String _buildPatterns({
    required double totalSpent,
    required double budgetTarget,
    required double previousMonthSpent,
  }) {
    final parts = <String>[];
    if (budgetTarget > 0) {
      final pct = (totalSpent / budgetTarget * 100).toStringAsFixed(0);
      parts.add('Used $pct% of budget.');
    }
    if (previousMonthSpent > 0) {
      final diff = totalSpent - previousMonthSpent;
      final change = (diff / previousMonthSpent * 100).abs().toStringAsFixed(0);
      parts.add(
        diff > 0
            ? 'Spending up $change% vs last month.'
            : 'Spending down $change% vs last month.',
      );
    }
    return parts.isEmpty ? 'No previous data available.' : parts.join(' ');
  }

  String _fallbackNarrative({
    required String monthKey,
    required double totalSpent,
    required double budgetTarget,
    required double previousMonthSpent,
  }) {
    final buf = StringBuffer(
      'ใน $monthKey คุณใช้จ่ายทั้งหมด ฿${totalSpent.toStringAsFixed(0)}',
    );
    if (budgetTarget > 0) {
      final pct = (totalSpent / budgetTarget * 100).toStringAsFixed(0);
      buf.write(' ($pct% of your ฿${budgetTarget.toStringAsFixed(0)} budget)');
    }
    if (previousMonthSpent > 0) {
      final diff = totalSpent - previousMonthSpent;
      final change = (diff / previousMonthSpent * 100).abs().toStringAsFixed(0);
      buf.write(
        diff > 0
            ? ', เพิ่มขึ้น $change% จากเดือนก่อน.'
            : ', ลดลง $change% จากเดือนก่อน.',
      );
    } else {
      buf.write('.');
    }
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  /// Returns the month prior to [dt] as a new [DateTime] at day 1.
  static DateTime _previousMonth(DateTime dt) {
    if (dt.month == 1) return DateTime(dt.year - 1, 12);
    return DateTime(dt.year, dt.month - 1);
  }

  /// Format a [DateTime] as "YYYY-MM".
  static String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  /// Parse "YYYY-MM" into the first moment of that month.
  static DateTime _monthStart(String monthKey) {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Parse "YYYY-MM" into the last moment of that month (23:59:59.999).
  static DateTime _monthEnd(String monthKey) {
    final start = _monthStart(monthKey);
    // First day of next month minus 1 millisecond.
    final nextMonth = start.month < 12
        ? DateTime(start.year, start.month + 1)
        : DateTime(start.year + 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
}
