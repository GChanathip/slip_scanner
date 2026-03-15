import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avers/services/budget_service.dart';

void main() {
  group('BudgetService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getOverallBudget returns 0 when not set', () async {
      final result = await BudgetService.getOverallBudget();
      expect(result, 0);
    });

    test('setOverallBudget stores and retrieves value', () async {
      await BudgetService.setOverallBudget(50000);
      final result = await BudgetService.getOverallBudget();
      expect(result, 50000);
    });

    test('getCategoryBudgets returns empty map when not set', () async {
      final result = await BudgetService.getCategoryBudgets();
      expect(result, isEmpty);
    });

    test('getCategoryBudgets parses stored JSON', () async {
      // Reset mock with the JSON data
      SharedPreferences.setMockInitialValues({});
      await BudgetService.setCategoryBudget('food', 5000);
      await BudgetService.setCategoryBudget('transport', 3000);
      await BudgetService.setCategoryBudget('utilities', 2000);

      final result = await BudgetService.getCategoryBudgets();

      expect(result['food'], 5000.0);
      expect(result['transport'], 3000.0);
      expect(result['utilities'], 2000.0);
    });

    test('setCategoryBudget adds new category', () async {
      await BudgetService.setCategoryBudget('food', 5000);
      final result = await BudgetService.getCategoryBudgets();

      expect(result['food'], 5000.0);
    });

    test('setCategoryBudget updates existing category', () async {
      await BudgetService.setCategoryBudget('food', 3000);
      await BudgetService.setCategoryBudget('food', 5000);
      final result = await BudgetService.getCategoryBudgets();

      expect(result['food'], 5000.0);
    });

    test('setCategoryBudget removes category when amount <= 0', () async {
      await BudgetService.setCategoryBudget('food', 5000);
      await BudgetService.setCategoryBudget('transport', 3000);
      await BudgetService.setCategoryBudget('food', 0);

      final result = await BudgetService.getCategoryBudgets();

      expect(result.containsKey('food'), false);
      expect(result['transport'], 3000.0);
    });

    test('clearAll removes all budget settings', () async {
      await BudgetService.setOverallBudget(50000);
      await BudgetService.setCategoryBudget('food', 5000);

      await BudgetService.clearAll();

      final overallBudget = await BudgetService.getOverallBudget();
      final categoryBudgets = await BudgetService.getCategoryBudgets();

      expect(overallBudget, 0);
      expect(categoryBudgets, isEmpty);
    });

    test('handles decimal amounts correctly', () async {
      await BudgetService.setOverallBudget(50000.50);
      final result = await BudgetService.getOverallBudget();

      expect(result, 50000.50);
    });

    test('handles large amounts', () async {
      await BudgetService.setOverallBudget(999999.99);
      final result = await BudgetService.getOverallBudget();

      expect(result, 999999.99);
    });

    test('multiple categories stored and retrieved correctly', () async {
      await BudgetService.setCategoryBudget('food', 5000);
      await BudgetService.setCategoryBudget('transport', 3000);
      await BudgetService.setCategoryBudget('utilities', 2000);

      final result = await BudgetService.getCategoryBudgets();

      expect(result.length, 3);
      expect(result['food'], 5000.0);
      expect(result['transport'], 3000.0);
      expect(result['utilities'], 2000.0);
    });
  });
}
