import 'package:flutter_test/flutter_test.dart';
import 'package:avers/providers/analysis_state.dart';
import 'package:avers/providers/budget_state.dart';
import 'package:avers/services/suggestion_chip_service.dart';

void main() {
  group('SuggestionChipService.generate', () {
    test('returns max 6 chips', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 5000, 'transport': 3000},
        topRecipients: {'7-Eleven': 2000},
        dailyTotals: {
          // Saturday + Sunday heavy weekend spending
          '2026-03-07': 3000.0, // Saturday
          '2026-03-08': 3000.0, // Sunday
          '2026-03-09': 1000.0, // Monday
        },
        insights: [
          InsightData(
            title: 'Spike',
            description: 'Food anomaly',
            type: 'anomaly',
          ),
        ],
        transactionCount: 10,
        totalSpending: 7000,
      );
      const budget = BudgetState(
        overallBudget: 10000,
        currentMonthSpent: 8000,
      );

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(chips.length, lessThanOrEqualTo(6));
    });

    test('includes budget alert chip when budget >= 75%', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 5000},
        transactionCount: 5,
      );
      const budget = BudgetState(
        overallBudget: 10000,
        currentMonthSpent: 7500,
      );

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(chips.any((c) => c.label == 'Am I over budget?'), isTrue);
    });

    test('no budget alert chip when budget < 75%', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 5000},
        transactionCount: 5,
      );
      const budget = BudgetState(
        overallBudget: 10000,
        currentMonthSpent: 5000,
      );

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(chips.any((c) => c.label == 'Am I over budget?'), isFalse);
    });

    test('no budget alert chip when no budget set', () {
      const analysis = AnalysisState(transactionCount: 5);
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(chips.any((c) => c.label == 'Am I over budget?'), isFalse);
    });

    test('includes category spike chip on anomaly insight', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 7000, 'transport': 3000},
        insights: [
          InsightData(
            title: 'Spike',
            description: 'Unusual food spending',
            type: 'anomaly',
          ),
        ],
        transactionCount: 10,
        totalSpending: 10000,
      );
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label.contains('Food')),
        isTrue,
      );
    });

    test('includes category spike chip when top category > 40% of total', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 5000, 'transport': 1000},
        transactionCount: 10,
        totalSpending: 6000,
      );
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label.contains('Food')),
        isTrue,
      );
    });

    test('includes weekend pattern chip when weekend > 35%', () {
      const analysis = AnalysisState(
        dailyTotals: {
          '2026-03-07': 4000.0, // Saturday
          '2026-03-08': 3000.0, // Sunday
          '2026-03-09': 1000.0, // Monday
          '2026-03-10': 1000.0, // Tuesday
        },
        transactionCount: 10,
        totalSpending: 9000,
      );
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label == 'My weekend spending'),
        isTrue,
      );
    });

    test('no weekend chip when weekend <= 35%', () {
      const analysis = AnalysisState(
        dailyTotals: {
          '2026-03-07': 1000.0, // Saturday
          '2026-03-09': 5000.0, // Monday
          '2026-03-10': 5000.0, // Tuesday
        },
        transactionCount: 10,
        totalSpending: 11000,
      );
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label == 'My weekend spending'),
        isFalse,
      );
    });

    test('includes top recipient chip when recipients exist', () {
      const analysis = AnalysisState(
        topRecipients: {'7-Eleven': 5000},
        transactionCount: 5,
      );
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label == 'Where does most money go?'),
        isTrue,
      );
    });

    test('always includes week comparison and monthly overview', () {
      const analysis = AnalysisState(transactionCount: 5);
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(
        chips.any((c) => c.label == 'This week vs last week'),
        isTrue,
      );
      expect(
        chips.any((c) => c.label == "How's my spending this month?"),
        isTrue,
      );
    });

    test('empty analysis returns at least fallback chips', () {
      const analysis = AnalysisState();
      const budget = BudgetState();

      final chips = SuggestionChipService.generate(analysis, budget);
      expect(chips.length, greaterThanOrEqualTo(2));
      expect(
        chips.last.label,
        "How's my spending this month?",
      );
    });

    test('chip query is non-empty for all chips', () {
      const analysis = AnalysisState(
        categoryBreakdown: {'food': 5000},
        topRecipients: {'7-Eleven': 3000},
        transactionCount: 5,
        totalSpending: 5000,
      );
      const budget = BudgetState(
        overallBudget: 10000,
        currentMonthSpent: 8000,
      );

      final chips = SuggestionChipService.generate(analysis, budget);
      for (final chip in chips) {
        expect(chip.query, isNotEmpty);
        expect(chip.label, isNotEmpty);
      }
    });
  });
}
