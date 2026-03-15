import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_state.freezed.dart';

@freezed
abstract class BudgetAlert with _$BudgetAlert {
  const factory BudgetAlert({
    required String label, // 'Overall' or category name
    required double spent,
    required double budget,
    required double percentage,
    required BudgetAlertLevel level,
  }) = _BudgetAlert;
}

enum BudgetAlertLevel { normal, info, warning, danger, exceeded }

@freezed
abstract class BudgetState with _$BudgetState {
  const BudgetState._();

  const factory BudgetState({
    @Default(0) double overallBudget,
    @Default({}) Map<String, double> categoryBudgets,
    @Default(0) double currentMonthSpent,
    @Default({}) Map<String, double> currentMonthByCategory,
    @Default([]) List<BudgetAlert> alerts,
    @Default(false) bool isLoading,
  }) = _BudgetState;

  bool get hasBudget => overallBudget > 0 || categoryBudgets.isNotEmpty;

  double get overallPercentage =>
      overallBudget > 0 ? (currentMonthSpent / overallBudget * 100).clamp(0, 999) : 0;

  String get monthlySummary {
    if (!hasBudget) return '';
    final buffer = StringBuffer();
    if (overallBudget > 0) {
      final remaining = overallBudget - currentMonthSpent;
      buffer.writeln('Monthly budget: ${overallBudget.toStringAsFixed(0)} baht');
      buffer.writeln('Spent so far: ${currentMonthSpent.toStringAsFixed(0)} baht (${overallPercentage.toStringAsFixed(0)}%)');
      buffer.writeln('Remaining: ${remaining.toStringAsFixed(0)} baht');
    }
    return buffer.toString();
  }
}
