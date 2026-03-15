import '../models/suggestion_chip.dart';
import '../providers/analysis_state.dart';
import '../providers/budget_state.dart';
import '../utils/formatters.dart';

class SuggestionChipService {
  /// Generate contextual suggestion chips (max 6, priority-ordered) from
  /// analysis and budget state.
  static List<SuggestionChip> generate(
    AnalysisState analysis,
    BudgetState budget,
  ) {
    final chips = <SuggestionChip>[];

    // 1. Budget alert — when budget >= 75%
    if (budget.hasBudget && budget.overallPercentage >= 75) {
      chips.add(const SuggestionChip(
        label: 'Am I over budget?',
        query: 'Am I over budget? How much have I spent vs my budget?',
        icon: 'alertTriangle',
      ));
    }

    // 2. Category spike — when anomaly insight exists or top category > 40%
    final anomaly = analysis.insights.where((i) => i.type == 'anomaly').firstOrNull;
    if (anomaly != null && analysis.topCategory != null) {
      final cat = formatCategory(analysis.topCategory!);
      chips.add(SuggestionChip(
        label: 'Why did I spend more on $cat?',
        query: 'Why did I spend more on $cat recently? Is this unusual?',
        icon: 'trendingUp',
      ));
    } else if (chips.length < 2 && analysis.categoryBreakdown.length > 1) {
      final total = analysis.categoryBreakdown.values.fold(0.0, (a, b) => a + b);
      if (total > 0 && analysis.topCategory != null) {
        final topSpend = analysis.categoryBreakdown[analysis.topCategory] ?? 0;
        if (topSpend / total > 0.40) {
          final cat = formatCategory(analysis.topCategory!);
          chips.add(SuggestionChip(
            label: 'Why did I spend more on $cat?',
            query: 'Why did I spend more on $cat recently? Is this unusual?',
            icon: 'trendingUp',
          ));
        }
      }
    }

    // 3. Weekend pattern — when weekend spend > 35% of total
    if (analysis.dailyTotals.isNotEmpty) {
      final allTotal = analysis.dailyTotals.values.fold(0.0, (a, b) => a + b);
      if (allTotal > 0 && _weekendTotal(analysis.dailyTotals) / allTotal > 0.35) {
        chips.add(const SuggestionChip(
          label: 'My weekend spending',
          query: 'Tell me about my weekend spending patterns. How much do I spend on weekends vs weekdays?',
          icon: 'calendar',
        ));
      }
    }

    // 4. Top recipient — always
    if (analysis.topRecipients.isNotEmpty) {
      chips.add(const SuggestionChip(
        label: 'Where does most money go?',
        query: 'Where does most of my money go? Who are my top recipients?',
        icon: 'arrowRightLeft',
      ));
    }

    // 5. Week comparison — always
    chips.add(const SuggestionChip(
      label: 'This week vs last week',
      query: 'Compare my spending this week versus last week',
      icon: 'barChart2',
    ));

    // 6. General fallback — always
    chips.add(const SuggestionChip(
      label: "How's my spending this month?",
      query: "Give me an overview of my spending this month",
      icon: 'pieChart',
    ));

    return chips.take(6).toList();
  }

  static double _weekendTotal(Map<String, double> dailyTotals) {
    double total = 0.0;
    for (final entry in dailyTotals.entries) {
      try {
        final date = DateTime.parse(entry.key);
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          total += entry.value;
        }
      } catch (_) {
        // Skip unparseable date keys
      }
    }
    return total;
  }
}
