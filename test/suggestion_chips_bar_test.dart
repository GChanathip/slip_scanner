import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:avers/features/chat/models/suggestion_chip.dart' as model;
import 'package:avers/features/chat/widgets/suggestion_chips_bar.dart';

/// Wraps a widget in the minimum forui + Material scaffolding needed for tests.
Widget _testApp(Widget child) {
  return MaterialApp(
    theme: FThemes.zinc.light.toApproximateMaterialTheme(),
    home: FTheme(
      data: FThemes.zinc.light,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SuggestionChipsBar', () {
    final sampleChips = const [
      model.SuggestionChip(
        label: 'Am I over budget?',
        query: 'Am I over budget?',
        icon: 'alertTriangle',
      ),
      model.SuggestionChip(
        label: 'This week vs last week',
        query: 'Compare spending this week vs last',
        icon: 'barChart2',
      ),
      model.SuggestionChip(
        label: "How's my spending?",
        query: 'Give me an overview',
        icon: 'pieChart',
      ),
    ];

    testWidgets('renders nothing when chips list is empty', (tester) async {
      model.SuggestionChip? tappedChip;

      await tester.pumpWidget(_testApp(
        SuggestionChipsBar(
          chips: const [],
          onChipTap: (c) => tappedChip = c,
        ),
      ));

      // SizedBox.shrink should render with zero size
      expect(find.byType(SuggestionChipsBar), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tappedChip, isNull);
    });

    testWidgets('renders all chip labels', (tester) async {
      await tester.pumpWidget(_testApp(
        SuggestionChipsBar(
          chips: sampleChips,
          onChipTap: (_) {},
        ),
      ));

      expect(find.text('Am I over budget?'), findsOneWidget);
      expect(find.text('This week vs last week'), findsOneWidget);
      expect(find.text("How's my spending?"), findsOneWidget);
    });

    testWidgets('fires onChipTap callback with correct chip', (tester) async {
      model.SuggestionChip? tappedChip;

      await tester.pumpWidget(_testApp(
        SuggestionChipsBar(
          chips: sampleChips,
          onChipTap: (c) => tappedChip = c,
        ),
      ));

      // Use gesture to control timing and let forui FTappable timers settle
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('This week vs last week')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tappedChip, isNotNull);
      expect(tappedChip!.label, 'This week vs last week');
      expect(tappedChip!.query, 'Compare spending this week vs last');
    });

    testWidgets('uses horizontal ListView', (tester) async {
      await tester.pumpWidget(_testApp(
        SuggestionChipsBar(
          chips: sampleChips,
          onChipTap: (_) {},
        ),
      ));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('has correct height of 44', (tester) async {
      await tester.pumpWidget(_testApp(
        SuggestionChipsBar(
          chips: sampleChips,
          onChipTap: (_) {},
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 44);
    });
  });
}
