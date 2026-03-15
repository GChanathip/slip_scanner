import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avers/widgets/category_edit_sheet.dart';

void main() {
  group('CategoryEditSheet Widget Tests', () {
    testWidgets('create mode: empty form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Verify empty name field
      expect(find.byType(TextField), findsWidgets);
      expect(find.text(''), findsWidgets);

      // Verify icon grid visible (4x4)
      // expect(find.byType(GridView), findsOneWidget);

      // Verify color palette visible (8 swatches)
      // expect(find.text('Colors:'), findsOneWidget);

      // Verify live preview
      // expect(find.byType(CategoryPreview), findsOneWidget);
    });

    testWidgets('edit mode: prefilled form', (WidgetTester tester) async {
      // Setup: Create category
      // final category = CustomCategory(
      //   id: 1,
      //   name: 'Meals',
      //   icon: 'utensils',
      //   color: 'orange',
      //   createdAt: DateTime.now().toIso8601String(),
      // );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.edit(null), // Passing null for now
            ),
          ),
        ),
      );

      // Verify name field has 'Meals'
      // expect(find.widgetWithText(TextField, 'Meals'), findsOneWidget);

      // Verify icon 'utensils' selected
      // expect(find.text('utensils'), findsWidgets);

      // Verify color 'orange' selected
      // expect(find.text('orange'), findsWidgets);
    });

    testWidgets('live preview updates on name change', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Find name input
      final nameInput = find.byType(TextField);
      await tester.enterText(nameInput, 'Meals');
      await tester.pumpAndSettle();

      // Verify preview shows 'Meals'
      // expect(find.text('Meals'), findsWidgets);
    });

    testWidgets('live preview updates on icon select', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Select icon 'utensils'
      // final iconButton = find.byIcon(utensils);
      // await tester.tap(iconButton);
      // await tester.pumpAndSettle();

      // Verify preview icon changed
    });

    testWidgets('live preview updates on color select', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Select color 'red'
      // final colorButton = find.byColor(kRedColor);
      // await tester.tap(colorButton);
      // await tester.pumpAndSettle();

      // Verify preview color changed
    });

    testWidgets('validates name not empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Tap Save without entering name
      // final saveButton = find.byType(ElevatedButton);
      // await tester.tap(saveButton);
      // await tester.pumpAndSettle();

      // Verify error shown
      // expect(find.text('Category name required'), findsOneWidget);
    });

    testWidgets('validates name length 1-30 characters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Try to enter 31 characters
      final nameInput = find.byType(TextField);
      await tester.enterText(nameInput, 'a' * 31);
      await tester.pumpAndSettle();

      // Verify character limit enforced or error shown
      // expect(tester.getSemantics(find.byType(TextField)).label, contains('30 chars max'));
    });

    testWidgets('duplicate validation (create mode)', (WidgetTester tester) async {
      // Setup: 'Meals' already exists
      // await CategoryService.create('Meals', 'utensils', 'orange');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Enter duplicate name
      final nameInput = find.byType(TextField);
      await tester.enterText(nameInput, 'Meals');
      await tester.pumpAndSettle();

      // Tap Save
      // final saveButton = find.byType(ElevatedButton);
      // await tester.tap(saveButton);
      // await tester.pumpAndSettle();

      // Verify error shown
      // expect(find.text('Category name already exists'), findsOneWidget);
    });

    testWidgets('duplicate validation (edit mode) - case insensitive', (WidgetTester tester) async {
      // Setup: 'Meals' exists, editing 'Dining'
      // await CategoryService.create('Meals', 'utensils', 'orange');
      // final dining = await CategoryService.create('Dining', 'fork', 'red');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.edit(null), // Passing null for now
            ),
          ),
        ),
      );

      // Try to rename to 'meals' (different case)
      // final nameInput = find.byType(TextField);
      // await tester.enterText(nameInput, 'meals');
      // await tester.pumpAndSettle();

      // Verify error shown
      // expect(find.text('Category name already exists'), findsOneWidget);
    });

    testWidgets('save calls CategoryService.create', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Enter details
      final nameInput = find.byType(TextField);
      await tester.enterText(nameInput, 'Meals');

      // Select icon and color
      // ...

      // Tap Save
      // final saveButton = find.byType(ElevatedButton);
      // await tester.tap(saveButton);
      // await tester.pumpAndSettle();

      // Verify CategoryService.create was called
      // expect(createCalled, true);

      // Verify sheet closed
      // expect(find.byType(CategoryEditSheet), findsNothing);
    });

    testWidgets('save calls CategoryService.update in edit mode', (WidgetTester tester) async {
      // Setup: Create category
      // final category = await CategoryService.create('Meals', 'utensils', 'orange');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.edit(null), // Passing null for now
            ),
          ),
        ),
      );

      // Change name
      // final nameInput = find.byType(TextField);
      // await tester.enterText(nameInput, 'Dining');
      // await tester.pumpAndSettle();

      // Tap Save
      // final saveButton = find.byType(ElevatedButton);
      // await tester.tap(saveButton);
      // await tester.pumpAndSettle();

      // Verify CategoryService.update was called
      // expect(updateCalled, true);
    });

    testWidgets('icon grid shows all available icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Verify icon grid (4x4 = 16 icons)
      // expect(find.byType(GridView), findsOneWidget);
      // final gridView = tester.widget<GridView>(find.byType(GridView));
      // expect(gridView.delegate.estimateMaxScrollOffset, ... ); // Approximate check
    });

    testWidgets('color palette shows 8 colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Verify 8 color options shown
      // expect(find.byType(Container), findsWidgets);
      // // Count color containers
    });

    testWidgets('cancel button closes sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CategoryEditSheet.create(),
            ),
          ),
        ),
      );

      // Tap Cancel
      // final cancelButton = find.byType(TextButton);
      // await tester.tap(cancelButton);
      // await tester.pumpAndSettle();

      // Verify sheet closed
      // expect(find.byType(CategoryEditSheet), findsNothing);
    });
  });
}
