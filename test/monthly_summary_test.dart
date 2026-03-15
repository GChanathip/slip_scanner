import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:avers/features/analysis/models/monthly_summary.dart';

void main() {
  group('MonthlySummary', () {
    late MonthlySummary summary;

    setUp(() {
      summary = MonthlySummary(
        month: '2026-02',
        totalSpent: 45000.50,
        budgetTarget: 50000,
        previousMonthSpent: 42000,
        categoryBreakdown: {
          'food': 15000,
          'transport': 8000,
          'shopping': 12000,
          'utilities': 5000,
          'other': 5000.50,
        },
        topRecipients: {
          '7-Eleven': 8000,
          'Grab': 5000,
          'Lotus': 3000,
        },
        narrative: 'ใน 2026-02 คุณใช้จ่ายทั้งหมด ฿45,001 (90% of budget).',
        generatedAt: DateTime(2026, 3, 1, 8, 0, 0),
      );
    });

    test('constructs with all fields', () {
      expect(summary.month, '2026-02');
      expect(summary.totalSpent, 45000.50);
      expect(summary.budgetTarget, 50000);
      expect(summary.previousMonthSpent, 42000);
      expect(summary.categoryBreakdown.length, 5);
      expect(summary.topRecipients.length, 3);
      expect(summary.narrative, isNotEmpty);
      expect(summary.generatedAt, DateTime(2026, 3, 1, 8, 0, 0));
    });

    group('JSON serialization', () {
      test('toJson produces valid map', () {
        final json = summary.toJson();

        expect(json['month'], '2026-02');
        expect(json['totalSpent'], 45000.50);
        expect(json['budgetTarget'], 50000);
        expect(json['previousMonthSpent'], 42000);
        expect(json['categoryBreakdown'], isA<Map>());
        expect(json['topRecipients'], isA<Map>());
        expect(json['narrative'], isNotEmpty);
        expect(json['generatedAt'], isA<String>());
      });

      test('fromJson reconstructs correctly', () {
        final json = summary.toJson();
        final restored = MonthlySummary.fromJson(json);

        expect(restored.month, summary.month);
        expect(restored.totalSpent, summary.totalSpent);
        expect(restored.budgetTarget, summary.budgetTarget);
        expect(restored.previousMonthSpent, summary.previousMonthSpent);
        expect(restored.categoryBreakdown, summary.categoryBreakdown);
        expect(restored.topRecipients, summary.topRecipients);
        expect(restored.narrative, summary.narrative);
        expect(restored.generatedAt, summary.generatedAt);
      });

      test('toJsonString/fromJsonString roundtrip', () {
        final jsonStr = summary.toJsonString();
        final restored = MonthlySummary.fromJsonString(jsonStr);

        expect(restored.month, summary.month);
        expect(restored.totalSpent, summary.totalSpent);
        expect(restored.budgetTarget, summary.budgetTarget);
        expect(restored.categoryBreakdown, summary.categoryBreakdown);
        expect(restored.topRecipients, summary.topRecipients);
      });

      test('toJsonString produces valid JSON', () {
        final jsonStr = summary.toJsonString();
        expect(() => jsonDecode(jsonStr), returnsNormally);
      });

      test('handles zero budget target', () {
        final noBudget = MonthlySummary(
          month: '2026-02',
          totalSpent: 30000,
          budgetTarget: 0,
          previousMonthSpent: 0,
          categoryBreakdown: {'food': 30000},
          topRecipients: {},
          narrative: 'Summary without budget.',
          generatedAt: DateTime(2026, 3, 1),
        );

        final restored =
            MonthlySummary.fromJsonString(noBudget.toJsonString());
        expect(restored.budgetTarget, 0);
        expect(restored.previousMonthSpent, 0);
        expect(restored.topRecipients, isEmpty);
      });

      test('handles empty category breakdown', () {
        final empty = MonthlySummary(
          month: '2026-01',
          totalSpent: 0,
          budgetTarget: 0,
          previousMonthSpent: 0,
          categoryBreakdown: {},
          topRecipients: {},
          narrative: 'No data.',
          generatedAt: DateTime(2026, 2, 1),
        );

        final restored =
            MonthlySummary.fromJsonString(empty.toJsonString());
        expect(restored.categoryBreakdown, isEmpty);
        expect(restored.totalSpent, 0);
      });

      test('preserves Thai text in narrative', () {
        final thaiNarrative = MonthlySummary(
          month: '2026-02',
          totalSpent: 45000,
          budgetTarget: 50000,
          previousMonthSpent: 42000,
          categoryBreakdown: {'food': 45000},
          topRecipients: {'ร้านอาหาร': 10000},
          narrative: 'ใน 2026-02 คุณใช้จ่ายทั้งหมด ฿45,000, เพิ่มขึ้น 7% จากเดือนก่อน.',
          generatedAt: DateTime(2026, 3, 1),
        );

        final restored =
            MonthlySummary.fromJsonString(thaiNarrative.toJsonString());
        expect(restored.narrative, contains('คุณใช้จ่าย'));
        expect(restored.topRecipients.containsKey('ร้านอาหาร'), isTrue);
      });
    });
  });
}
