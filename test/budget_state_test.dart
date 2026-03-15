import 'package:flutter_test/flutter_test.dart';
import 'package:slip_scanner/providers/budget_state.dart';

void main() {
  group('BudgetAlert', () {
    test('creates alert with all fields', () {
      const alert = BudgetAlert(
        label: 'Food',
        spent: 3000,
        budget: 5000,
        percentage: 60,
        level: BudgetAlertLevel.warning,
      );

      expect(alert.label, 'Food');
      expect(alert.spent, 3000);
      expect(alert.budget, 5000);
      expect(alert.percentage, 60);
      expect(alert.level, BudgetAlertLevel.warning);
    });

    test('supports equality comparison', () {
      const alert1 = BudgetAlert(
        label: 'Food',
        spent: 3000,
        budget: 5000,
        percentage: 60,
        level: BudgetAlertLevel.warning,
      );
      const alert2 = BudgetAlert(
        label: 'Food',
        spent: 3000,
        budget: 5000,
        percentage: 60,
        level: BudgetAlertLevel.warning,
      );

      expect(alert1, alert2);
    });
  });

  group('BudgetState', () {
    test('hasBudget returns false when no budget set', () {
      const state = BudgetState();

      expect(state.hasBudget, false);
    });

    test('hasBudget returns true when overall budget set', () {
      const state = BudgetState(overallBudget: 50000);

      expect(state.hasBudget, true);
    });

    test('hasBudget returns true when category budget set', () {
      const state = BudgetState(
        categoryBudgets: {'food': 5000},
      );

      expect(state.hasBudget, true);
    });

    test('overallPercentage calculates correctly', () {
      const state = BudgetState(
        overallBudget: 10000,
        currentMonthSpent: 7500,
      );

      expect(state.overallPercentage, 75);
    });

    test('overallPercentage returns 0 when budget is 0', () {
      const state = BudgetState(
        overallBudget: 0,
        currentMonthSpent: 5000,
      );

      expect(state.overallPercentage, 0);
    });

    test('overallPercentage clamps to 999', () {
      const state = BudgetState(
        overallBudget: 1000,
        currentMonthSpent: 15000,
      );

      expect(state.overallPercentage, 999);
    });

    test('monthlySummary returns empty string when no budget', () {
      const state = BudgetState();

      expect(state.monthlySummary, '');
    });

    test('monthlySummary formats overall budget correctly', () {
      const state = BudgetState(
        overallBudget: 50000,
        currentMonthSpent: 30000,
      );

      final summary = state.monthlySummary;
      expect(summary, contains('Monthly budget: 50000 baht'));
      expect(summary, contains('Spent so far: 30000 baht (60%)'));
      expect(summary, contains('Remaining: 20000 baht'));
    });

    test('monthlySummary handles decimal amounts', () {
      const state = BudgetState(
        overallBudget: 50000.50,
        currentMonthSpent: 25000.75,
      );

      final summary = state.monthlySummary;
      expect(summary, contains('Monthly budget: 50001 baht'));
      expect(summary, contains('Spent so far: 25001 baht'));
    });

    test('copyWith updates specific fields', () {
      const state = BudgetState(
        overallBudget: 50000,
        currentMonthSpent: 20000,
      );

      final updated = state.copyWith(currentMonthSpent: 30000);

      expect(updated.overallBudget, 50000);
      expect(updated.currentMonthSpent, 30000);
    });

    test('isLoading defaults to false', () {
      const state = BudgetState();

      expect(state.isLoading, false);
    });

    test('maintains all fields in constructor', () {
      const alerts = [
        BudgetAlert(
          label: 'Food',
          spent: 3000,
          budget: 5000,
          percentage: 60,
          level: BudgetAlertLevel.warning,
        )
      ];
      const categoryBudgets = {'food': 5000.0, 'transport': 3000.0};
      const categorySpent = {'food': 3000.0, 'transport': 1500.0};

      const state = BudgetState(
        overallBudget: 10000,
        categoryBudgets: categoryBudgets,
        currentMonthSpent: 5000,
        currentMonthByCategory: categorySpent,
        alerts: alerts,
        isLoading: true,
      );

      expect(state.overallBudget, 10000);
      expect(state.categoryBudgets, categoryBudgets);
      expect(state.currentMonthSpent, 5000);
      expect(state.currentMonthByCategory, categorySpent);
      expect(state.alerts, alerts);
      expect(state.isLoading, true);
    });
  });
}
