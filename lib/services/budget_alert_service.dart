import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

const _kBudgetAlertsFired = 'budget_alerts_fired';

// Ordered list of thresholds to check (lowest first so we fire all crossed thresholds).
const _thresholds = [50.0, 75.0, 90.0, 100.0];

/// Checks whether spending has crossed budget notification thresholds after
/// each slip extraction. Deduplicates alerts so the same threshold fires at
/// most once per calendar month.
class BudgetAlertService {
  BudgetAlertService._();
  static final BudgetAlertService instance = BudgetAlertService._();

  /// Called after a slip is extracted. Queries current-month spending, compares
  /// against the overall budget target, and fires a local notification for any
  /// threshold not yet fired this month.
  Future<void> checkThresholds() async {
    try {
      final overallBudget = await BudgetService.getOverallBudget();
      if (overallBudget <= 0) return; // No budget configured

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final spent = await DatabaseService.getTotalForPeriod(monthStart, now);
      if (spent <= 0) return;

      final percentage = (spent / overallBudget) * 100;

      // Month key: "2026_03" — resets alerts each new month
      final monthKey =
          '${now.year}_${now.month.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      final firedJson = prefs.getString(_kBudgetAlertsFired);
      final fired = firedJson != null
          ? Map<String, bool>.from(
              (jsonDecode(firedJson) as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v as bool)),
            )
          : <String, bool>{};

      bool anyFired = false;
      for (final threshold in _thresholds) {
        if (percentage < threshold) continue; // Not reached yet

        final alertKey = '${monthKey}_${threshold.toInt()}';
        if (fired[alertKey] == true) continue; // Already fired this month

        await _fireAlert(threshold, spent, overallBudget);
        fired[alertKey] = true;
        anyFired = true;
      }

      if (anyFired) {
        await prefs.setString(_kBudgetAlertsFired, jsonEncode(fired));
      }
    } catch (e) {
      debugPrint('BudgetAlertService error: $e');
    }
  }

  Future<void> _fireAlert(
    double threshold,
    double spent,
    double budget,
  ) async {
    final budgetStr = '฿${budget.toStringAsFixed(0)}';
    final spentStr = '฿${spent.toStringAsFixed(0)}';
    final pctStr = '${threshold.toInt()}%';

    final String title;
    final String body;

    if (threshold >= 100) {
      title = 'Budget Exceeded!';
      body = 'You\'ve spent $spentStr — your $budgetStr monthly budget is over.';
    } else {
      title = 'Budget Alert';
      body =
          'You\'ve spent $pctStr of your $budgetStr budget ($spentStr spent).';
    }

    // Use threshold as the notification ID so each level has a stable ID.
    await NotificationService.instance.show(threshold.toInt(), title, body);
  }
}
