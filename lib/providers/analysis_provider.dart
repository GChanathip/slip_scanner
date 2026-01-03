import 'dart:convert';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/database_service.dart';
import '../services/cactus_service.dart';
import '../models/payment_slip.dart';
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

      // Generate insights
      final insights = await _generateInsights(slips, categoryBreakdown, monthlyTrend);

      state = state.copyWith(
        categoryBreakdown: categoryBreakdown,
        monthlyTrend: monthlyTrend,
        totalSpending: total,
        transactionCount: count,
        averageTransaction: avg,
        insights: insights,
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
    // Always include basic insights
    final basicInsights = _generateBasicInsights(slips, categories, monthly);

    // Try to get AI-powered insights if model is loaded
    if (!CactusService.instance.isLoaded) {
      return basicInsights;
    }

    try {
      final aiInsights = await _generateAIInsights(slips, categories, monthly);
      // Combine: AI insights first, then basic insights
      return [...aiInsights, ...basicInsights];
    } catch (e) {
      debugPrint('AI insights failed: $e');
      return basicInsights;
    }
  }

  /// Generate basic statistical insights
  List<InsightData> _generateBasicInsights(
    List<PaymentSlip> slips,
    Map<String, double> categories,
    Map<String, double> monthly,
  ) {
    final insights = <InsightData>[];
    final total = slips.fold<double>(0, (sum, s) => sum + s.amount);

    // Top category
    if (categories.isNotEmpty) {
      final topEntry = categories.entries.reduce((a, b) => a.value > b.value ? a : b);
      final percentage = (topEntry.value / total * 100).toStringAsFixed(1);
      insights.add(InsightData(
        title: 'Top Category',
        description: '${_formatCategory(topEntry.key)} is your highest spending at $percentage% of total',
        type: 'trend',
        value: topEntry.value,
        icon: 'chart',
      ));
    }

    // Monthly comparison (if we have multiple months)
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

  /// Format category name for display
  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Refresh analysis with current date range
  Future<void> refresh() async {
    await loadAnalysis(startDate: state.startDate, endDate: state.endDate);
  }

  /// Set date range and reload
  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    await loadAnalysis(startDate: start, endDate: end);
  }
}
