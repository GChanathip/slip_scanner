import 'dart:convert';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/database_service.dart';
import '../services/cactus_service.dart';
import '../models/payment_slip.dart';
import '../utils/formatters.dart';
import 'analysis_state.dart';

part 'analysis_provider.g.dart';

@riverpod
class Analysis extends _$Analysis {
  @override
  AnalysisState build() => const AnalysisState();

  /// Load analysis for a date range
  Future<void> loadAnalysis({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(
      isLoading: true,
      startDate: startDate,
      endDate: endDate,
      error: null,
    );

    try {
      final slips = await DatabaseService.getPaymentSlipsInRange(
        startDate ?? DateTime(2000),
        endDate ?? DateTime.now(),
      );

      if (slips.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          insights: [
            const InsightData(
              title: 'No Data',
              description: 'No expense records found for this period',
              type: 'trend',
              icon: 'info',
            ),
          ],
        );
        return;
      }

      // Calculate totals
      final total = slips.fold<double>(0, (sum, s) => sum + s.amount);
      final count = slips.length;
      final avg = count > 0 ? total / count : 0.0;

      // Calculate category breakdown
      final categoryBreakdown = <String, double>{};
      for (final slip in slips) {
        final cat = slip.category ?? 'uncategorized';
        categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + slip.amount;
      }

      // Calculate monthly trend
      final monthlyTrend = <String, double>{};
      for (final slip in slips) {
        final monthKey = '${slip.date.year}-${slip.date.month.toString().padLeft(2, '0')}';
        monthlyTrend[monthKey] = (monthlyTrend[monthKey] ?? 0) + slip.amount;
      }

      // Load detailed analytics in parallel
      final effectiveStart = startDate ?? DateTime(2000);
      final effectiveEnd = endDate ?? DateTime.now();

      final results = await Future.wait([
        DatabaseService.getDailyTotals(effectiveStart, effectiveEnd),
        DatabaseService.getWeeklyTotals(effectiveStart, effectiveEnd),
        DatabaseService.getTopRecipients(effectiveStart, effectiveEnd),
        DatabaseService.getCategoryTrend(effectiveStart, effectiveEnd),
        _generateInsights(slips, categoryBreakdown, monthlyTrend),
      ]);

      final dailyTotals = results[0] as Map<String, double>;
      final weeklyTotals = results[1] as Map<String, double>;
      final topRecipients = results[2] as Map<String, double>;
      final categoryTrend = results[3] as Map<String, Map<String, double>>;
      final insights = results[4] as List<InsightData>;

      state = state.copyWith(
        categoryBreakdown: categoryBreakdown,
        monthlyTrend: monthlyTrend,
        totalSpending: total,
        transactionCount: count,
        averageTransaction: avg,
        insights: insights,
        dailyTotals: dailyTotals,
        weeklyTotals: weeklyTotals,
        topRecipients: topRecipients,
        categoryTrend: categoryTrend,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading analysis: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Generate insights using LLM or fallback to basic insights
  Future<List<InsightData>> _generateInsights(
    List<PaymentSlip> slips,
    Map<String, double> categories,
    Map<String, double> monthly,
  ) async {
    // Always include basic insights (now async for richer data)
    final basicInsights = await _generateBasicInsights(slips, categories, monthly);

    // Try to get AI-powered insights if model is loaded
    if (!CactusService.instance.isLoaded) {
      return basicInsights;
    }

    try {
      final aiInsights = await _generateAIInsights(slips, categories, monthly);
      return [...aiInsights, ...basicInsights];
    } catch (e) {
      debugPrint('AI insights failed: $e');
      return basicInsights;
    }
  }

  /// Generate basic statistical insights enriched with pattern data
  Future<List<InsightData>> _generateBasicInsights(
    List<PaymentSlip> slips,
    Map<String, double> categories,
    Map<String, double> monthly,
  ) async {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final insights = <InsightData>[];
    final total = slips.fold<double>(0, (sum, s) => sum + s.amount);

    // Top category
    if (categories.isNotEmpty) {
      final topEntry = categories.entries.reduce((a, b) => a.value > b.value ? a : b);
      final percentage = (topEntry.value / total * 100).toStringAsFixed(1);
      insights.add(InsightData(
        title: 'Top Category',
        description: '${formatCategory(topEntry.key)} is your highest spending at $percentage% of total',
        type: 'trend',
        value: topEntry.value,
        icon: 'chart',
      ));
    }

    // Monthly comparison
    if (monthly.length >= 2) {
      final sortedMonths = monthly.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
      if (sortedMonths.length >= 2) {
        final current = sortedMonths[0].value;
        final previous = sortedMonths[1].value;
        final change = ((current - previous) / previous * 100);

        if (change.abs() > 5) {
          insights.add(InsightData(
            title: change > 0 ? 'Spending Up' : 'Spending Down',
            description:
                'This month is ${change.abs().toStringAsFixed(1)}% ${change > 0 ? 'higher' : 'lower'} than last month',
            type: change > 20 ? 'anomaly' : 'trend',
            value: change,
            icon: change > 0 ? 'trending_up' : 'trending_down',
          ));
        }
      }
    }

    // Large transaction alert
    final avgAmount = total / slips.length;
    final largeTransactions = slips.where((s) => s.amount > avgAmount * 3).toList();
    if (largeTransactions.isNotEmpty) {
      insights.add(InsightData(
        title: 'Large Transactions',
        description: '${largeTransactions.length} transactions are 3x above average',
        type: 'anomaly',
        value: largeTransactions.length.toDouble(),
        icon: 'alert',
      ));
    }

    // Day-of-week pattern
    try {
      final start = state.startDate ?? DateTime(2000);
      final end = state.endDate ?? DateTime.now();
      final dowTotals = await DatabaseService.getDayOfWeekTotals(start, end);
      if (dowTotals.length >= 3) {
        final weekdayTotal = [1, 2, 3, 4, 5].fold(0.0, (s, d) => s + (dowTotals[d] ?? 0));
        final weekendTotal = [0, 6].fold(0.0, (s, d) => s + (dowTotals[d] ?? 0));
        final allTotal = weekdayTotal + weekendTotal;
        if (allTotal > 0 && weekendTotal > 0) {
          final weekendPct = (weekendTotal / allTotal * 100);
          // Weekend is 2/7 = 28.6%, flag if significantly above
          if (weekendPct > 35) {
            insights.add(InsightData(
              title: 'Weekend Spender',
              description: '${weekendPct.toStringAsFixed(0)}% of spending happens on weekends',
              type: 'trend',
              value: weekendPct,
              icon: 'chart',
            ));
          }
        }
        // Highlight the highest spending day
        final topDay = dowTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
        final dowAvg = dowTotals.values.reduce((a, b) => a + b) / dowTotals.length;
        if (topDay.value > dowAvg * 1.5) {
          insights.add(InsightData(
            title: '${dayNames[topDay.key]} Peak',
            description: 'You spend ${((topDay.value / dowAvg - 1) * 100).toStringAsFixed(0)}% more on ${dayNames[topDay.key]}s',
            type: 'trend',
            value: topDay.value,
            icon: 'chart',
          ));
        }
      }
    } catch (e) {
      debugPrint('Day-of-week insight failed: $e');
    }

    // Spending velocity
    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      final dayOfMonth = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final currentTotal = await DatabaseService.getTotalForPeriod(currentMonthStart, now);
      final lastTotal = await DatabaseService.getTotalForPeriod(lastMonthStart, lastMonthEnd);

      if (currentTotal > 0 && lastTotal > 0 && dayOfMonth > 3) {
        final projectedTotal = (currentTotal / dayOfMonth) * daysInMonth;
        final diff = projectedTotal - lastTotal;
        final pct = (diff / lastTotal * 100);
        if (pct.abs() > 10) {
          insights.add(InsightData(
            title: 'Spending Velocity',
            description: 'At current rate, you\'ll spend ${formatCurrencyCompact(projectedTotal)} this month vs. ${formatCurrencyCompact(lastTotal)} last month (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%)',
            type: pct > 20 ? 'anomaly' : 'trend',
            value: pct,
            icon: pct > 0 ? 'trending_up' : 'trending_down',
          ));
        }
      }
    } catch (e) {
      debugPrint('Spending velocity insight failed: $e');
    }

    // Recipient concentration
    try {
      final start = state.startDate ?? DateTime(2000);
      final end = state.endDate ?? DateTime.now();
      final topRecipients = await DatabaseService.getTopRecipients(start, end, limit: 3);
      if (topRecipients.isNotEmpty && total > 0) {
        final topTotal = topRecipients.values.fold(0.0, (s, v) => s + v);
        final topPct = (topTotal / total * 100);
        if (topPct > 40) {
          insights.add(InsightData(
            title: 'Recipient Concentration',
            description: 'Top ${topRecipients.length} recipients account for ${topPct.toStringAsFixed(0)}% of spending',
            type: 'suggestion',
            value: topPct,
            icon: 'info',
          ));
        }
      }
    } catch (e) {
      debugPrint('Recipient insight failed: $e');
    }

    // Category anomaly detection (spike vs. historical average)
    try {
      final now = DateTime.now();
      final histStart = DateTime(now.year, now.month - 3, 1);
      final histEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      final historicalAvgs = await DatabaseService.getCategoryAverages(histStart, histEnd);

      for (final entry in categories.entries) {
        final histAvg = historicalAvgs[entry.key];
        if (histAvg != null && histAvg > 0) {
          final spike = ((entry.value - histAvg) / histAvg * 100);
          if (spike > 50) {
            insights.add(InsightData(
              title: '${formatCategory(entry.key)} Spike',
              description: '${formatCategory(entry.key)} spending is ${spike.toStringAsFixed(0)}% above 3-month average',
              type: 'anomaly',
              value: spike,
              icon: 'alert',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Category anomaly insight failed: $e');
    }

    return insights;
  }

  /// Generate AI-powered insights
  Future<List<InsightData>> _generateAIInsights(
    List<PaymentSlip> slips,
    Map<String, double> categories,
    Map<String, double> monthly,
  ) async {
    final total = slips.fold<double>(0, (sum, s) => sum + s.amount);

    final prompt = '''Analyze these expense patterns and provide 2-3 brief, actionable insights.

Category spending: ${categories.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} baht').join(', ')}
Monthly totals: ${monthly.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} baht').join(', ')}
Total: ${total.toStringAsFixed(2)} baht across ${slips.length} transactions

Respond in JSON array format only:
[{"title": "short title", "description": "1 sentence insight", "type": "suggestion"}]

Focus on actionable budget advice. Keep it brief.''';

    final result = await CactusService.instance.generateCompletion([
      ChatMessage(content: prompt, role: 'user'),
    ]);

    if (result.success) {
      return _parseAIInsights(result.response);
    }
    return [];
  }

  /// Parse AI insights from JSON response
  List<InsightData> _parseAIInsights(String jsonResponse) {
    try {
      // Find JSON array in response
      String jsonStr = jsonResponse.trim();
      final startIdx = jsonStr.indexOf('[');
      final endIdx = jsonStr.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final list = jsonDecode(jsonStr) as List;
      return list.map((item) {
        return InsightData(
          title: item['title']?.toString() ?? 'Insight',
          description: item['description']?.toString() ?? '',
          type: item['type']?.toString() ?? 'suggestion',
          icon: 'lightbulb',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing AI insights: $e');
      return [];
    }
  }

  /// Refresh analysis with current date range
  Future<void> refresh() async {
    await loadAnalysis(startDate: state.startDate, endDate: state.endDate);
  }

  /// Set date range and reload
  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    await loadAnalysis(startDate: start, endDate: end);
  }

  /// Switch active analytics view
  void setActiveView(AnalyticsView view) {
    state = state.copyWith(activeView: view);
  }
}
