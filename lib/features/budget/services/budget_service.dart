import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kBudgetOverall = 'budget_monthly_overall';
const _kBudgetCategories = 'budget_monthly_categories';

/// Budget storage using SharedPreferences.
/// Stores monthly overall target and per-category targets.
class BudgetService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the monthly overall budget target (0 = not set).
  static Future<double> getOverallBudget() async {
    final prefs = await _preferences;
    return prefs.getDouble(_kBudgetOverall) ?? 0;
  }

  /// Set the monthly overall budget target.
  static Future<void> setOverallBudget(double amount) async {
    final prefs = await _preferences;
    await prefs.setDouble(_kBudgetOverall, amount);
  }

  /// Get per-category budget targets.
  static Future<Map<String, double>> getCategoryBudgets() async {
    final prefs = await _preferences;
    final json = prefs.getString(_kBudgetCategories);
    if (json == null) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Set a per-category budget target.
  static Future<void> setCategoryBudget(String category, double amount) async {
    final budgets = await getCategoryBudgets();
    if (amount <= 0) {
      budgets.remove(category);
    } else {
      budgets[category] = amount;
    }
    final prefs = await _preferences;
    await prefs.setString(_kBudgetCategories, jsonEncode(budgets));
  }

  /// Clear all budget settings.
  static Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_kBudgetOverall);
    await prefs.remove(_kBudgetCategories);
  }
}
