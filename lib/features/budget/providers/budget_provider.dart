import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:avers/features/budget/services/budget_service.dart';
import 'package:avers/core/database/database_service.dart';
import 'package:avers/core/services/notification_service.dart';
import 'package:avers/features/budget/providers/budget_state.dart';

part 'budget_provider.g.dart';

@riverpod
class Budget extends _$Budget {
  @override
  BudgetState build() {
    // Trigger initial load
    Future.microtask(() => loadBudget());
    return const BudgetState(isLoading: true);
  }

  /// Load budget settings and current spending
  Future<void> loadBudget() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        BudgetService.getOverallBudget(),
        BudgetService.getCategoryBudgets(),
        DatabaseService.getTotalForPeriod(monthStart, now),
        _getCurrentMonthCategories(monthStart, now),
      ]);

      final overallBudget = results[0] as double;
      final categoryBudgets = results[1] as Map<String, double>;
      final currentSpent = results[2] as double;
      final categorySpent = results[3] as Map<String, double>;

      final alerts = _computeAlerts(overallBudget, categoryBudgets, currentSpent, categorySpent);

      state = BudgetState(
        overallBudget: overallBudget,
        categoryBudgets: categoryBudgets,
        currentMonthSpent: currentSpent,
        currentMonthByCategory: categorySpent,
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading budget: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Set overall monthly budget
  Future<void> setOverallBudget(double amount) async {
    final wasUnset = state.overallBudget <= 0;
    await BudgetService.setOverallBudget(amount);
    if (wasUnset && amount > 0) {
      // First time a budget is set — request notification permission
      await NotificationService.instance.requestPermission();
    }
    await loadBudget();
  }

  /// Set per-category budget
  Future<void> setCategoryBudget(String category, double amount) async {
    await BudgetService.setCategoryBudget(category, amount);
    await loadBudget();
  }

  Future<Map<String, double>> _getCurrentMonthCategories(DateTime start, DateTime end) async {
    final slips = await DatabaseService.getPaymentSlipsInRange(start, end);
    final byCategory = <String, double>{};
    for (final slip in slips) {
      final cat = slip.category ?? 'uncategorized';
      byCategory[cat] = (byCategory[cat] ?? 0) + slip.amount;
    }
    return byCategory;
  }

  List<BudgetAlert> _computeAlerts(
    double overallBudget,
    Map<String, double> categoryBudgets,
    double currentSpent,
    Map<String, double> categorySpent,
  ) {
    final alerts = <BudgetAlert>[];

    // Overall budget alert
    if (overallBudget > 0) {
      final pct = currentSpent / overallBudget * 100;
      final level = _alertLevel(pct);
      if (level != BudgetAlertLevel.normal) {
        alerts.add(BudgetAlert(
          label: 'Overall',
          spent: currentSpent,
          budget: overallBudget,
          percentage: pct,
          level: level,
        ));
      }
    }

    // Per-category alerts
    for (final entry in categoryBudgets.entries) {
      final spent = categorySpent[entry.key] ?? 0;
      final pct = entry.value > 0 ? spent / entry.value * 100 : 0.0;
      final level = _alertLevel(pct);
      if (level != BudgetAlertLevel.normal) {
        alerts.add(BudgetAlert(
          label: entry.key,
          spent: spent,
          budget: entry.value,
          percentage: pct,
          level: level,
        ));
      }
    }

    // Sort by severity (exceeded first)
    alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
    return alerts;
  }

  BudgetAlertLevel _alertLevel(double percentage) {
    if (percentage >= 100) return BudgetAlertLevel.exceeded;
    if (percentage >= 90) return BudgetAlertLevel.danger;
    if (percentage >= 75) return BudgetAlertLevel.warning;
    if (percentage >= 50) return BudgetAlertLevel.info;
    return BudgetAlertLevel.normal;
  }
}
