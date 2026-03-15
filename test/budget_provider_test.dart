import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avers/providers/budget_provider.dart';
import 'package:avers/providers/budget_state.dart';

void main() {
  group('BudgetProvider', () {
    test('initializes with loading state', () {
      final container = ProviderContainer();
      final state = container.read(budgetProvider);

      expect(state.isLoading, true);
    });

    test('initial state has no budget set', () {
      final container = ProviderContainer();
      final state = container.read(budgetProvider);

      expect(state.hasBudget, false);
      expect(state.alerts, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const state = BudgetState(
        overallBudget: 50000,
        currentMonthSpent: 20000,
      );

      final updated = state.copyWith(currentMonthSpent: 30000);

      expect(updated.overallBudget, 50000);
      expect(updated.currentMonthSpent, 30000);
    });

    test('BudgetAlertLevel has expected values', () {
      expect(
        [
          BudgetAlertLevel.normal,
          BudgetAlertLevel.warning,
          BudgetAlertLevel.danger,
          BudgetAlertLevel.exceeded,
        ].length,
        4,
      );
    });
  });
}
