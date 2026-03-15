import 'package:avers/core/database/database_service.dart';
import 'package:avers/features/analysis/models/what_if_scenario.dart';

class ScenarioService {
  /// Compute what-if spending projections for the top spending categories.
  ///
  /// Uses 3-month rolling category averages. Returns scenarios sorted by
  /// [currentMonthlyAvg] descending (highest spenders first).
  static Future<List<WhatIfScenario>> generateScenarios() async {
    final averages = await DatabaseService.getCategoryMonthlyAverages();
    if (averages.isEmpty) return [];

    final scenarios = averages.entries
        .where((e) => e.value > 0)
        .map((e) => WhatIfScenario.fromMonthlyAvg(e.key, e.value))
        .toList()
      ..sort((a, b) => b.currentMonthlyAvg.compareTo(a.currentMonthlyAvg));

    return scenarios;
  }
}
