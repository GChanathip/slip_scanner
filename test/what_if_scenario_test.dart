import 'package:flutter_test/flutter_test.dart';
import 'package:avers/models/what_if_scenario.dart';

void main() {
  group('WhatIfScenario', () {
    test('fromMonthlyAvg computes correct monthly savings', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('food', 10000);

      expect(scenario.category, 'food');
      expect(scenario.currentMonthlyAvg, 10000);
      expect(scenario.savingsByReductionPct[10], 1000);
      expect(scenario.savingsByReductionPct[20], 2000);
      expect(scenario.savingsByReductionPct[30], 3000);
    });

    test('fromMonthlyAvg computes correct annualized savings', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('transport', 5000);

      expect(scenario.annualizedSavings[10], 6000); // 500 * 12
      expect(scenario.annualizedSavings[20], 12000); // 1000 * 12
      expect(scenario.annualizedSavings[30], 18000); // 1500 * 12
    });

    test('fromMonthlyAvg with zero average', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('shopping', 0);

      expect(scenario.currentMonthlyAvg, 0);
      expect(scenario.savingsByReductionPct[10], 0);
      expect(scenario.savingsByReductionPct[20], 0);
      expect(scenario.savingsByReductionPct[30], 0);
      expect(scenario.annualizedSavings[10], 0);
      expect(scenario.annualizedSavings[20], 0);
      expect(scenario.annualizedSavings[30], 0);
    });

    test('fromMonthlyAvg with decimal amounts', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('utilities', 3333.33);

      expect(
        scenario.savingsByReductionPct[10],
        closeTo(333.333, 0.01),
      );
      expect(
        scenario.savingsByReductionPct[20],
        closeTo(666.666, 0.01),
      );
      expect(
        scenario.annualizedSavings[30],
        closeTo(11999.988, 0.01),
      );
    });

    test('has all three reduction percentages', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('food', 10000);

      expect(scenario.savingsByReductionPct.keys, containsAll([10, 20, 30]));
      expect(scenario.annualizedSavings.keys, containsAll([10, 20, 30]));
    });

    test('savings are proportional', () {
      final scenario = WhatIfScenario.fromMonthlyAvg('food', 10000);

      // 20% savings should be exactly 2x 10% savings
      expect(
        scenario.savingsByReductionPct[20],
        scenario.savingsByReductionPct[10]! * 2,
      );
      // 30% savings should be exactly 3x 10% savings
      expect(
        scenario.savingsByReductionPct[30],
        scenario.savingsByReductionPct[10]! * 3,
      );
    });
  });
}
