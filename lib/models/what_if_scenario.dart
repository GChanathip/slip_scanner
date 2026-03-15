/// Represents a what-if spending projection for a single category.
class WhatIfScenario {
  final String category;
  final double currentMonthlyAvg;

  /// Monthly savings at each reduction percentage (10, 20, 30).
  final Map<int, double> savingsByReductionPct;

  /// Annualized savings at each reduction percentage (monthly * 12).
  final Map<int, double> annualizedSavings;

  WhatIfScenario({
    required this.category,
    required this.currentMonthlyAvg,
    required this.savingsByReductionPct,
    required this.annualizedSavings,
  });

  factory WhatIfScenario.fromMonthlyAvg(String category, double monthlyAvg) {
    const reductions = [10, 20, 30];
    final monthly = {for (final pct in reductions) pct: monthlyAvg * pct / 100};
    final annual = {for (final pct in reductions) pct: monthly[pct]! * 12};
    return WhatIfScenario(
      category: category,
      currentMonthlyAvg: monthlyAvg,
      savingsByReductionPct: monthly,
      annualizedSavings: annual,
    );
  }
}
