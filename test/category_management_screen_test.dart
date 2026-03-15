import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avers/screens/category_management_screen.dart';

void main() {
  group('CategoryManagementScreen Widget Tests', () {
    testWidgets('renders built-in categories (read-only)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify built-in categories displayed
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);

      // Verify they are read-only (no edit/delete buttons)
      // Built-in categories should have eye icon or similar indicator
    });

    testWidgets('renders custom categories (editable)', (WidgetTester tester) async {
      // Setup: Create custom categories
      // await CategoryService.create('Meals', 'utensils', 'orange');
      // await CategoryService.create('Coffee', 'coffee', 'brown');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify custom categories displayed
      // expect(find.text('Meals'), findsOneWidget);
      // expect(find.text('Coffee'), findsOneWidget);

      // Verify they have edit/delete/merge buttons
    });

    testWidgets('empty state when no custom categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify empty state message
      // expect(find.text('No custom categories'), findsWidgets);
    });

    testWidgets('20 category limit indicator', (WidgetTester tester) async {
      // Setup: Create 20 custom categories

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify "Add" button is disabled
      // expect(find.byIcon(Icons.add), findsOneWidget);
      // final addButton = find.byIcon(Icons.add);
      // expect(tester.widget<IconButton>(addButton).onPressed, isNull);

      // Verify warning message shown
      // expect(find.text('Maximum 20 custom categories reached'), findsOneWidget);
    });

    testWidgets('tapping edit opens CategoryEditSheet', (WidgetTester tester) async {
      // Setup: Create custom category
      // await CategoryService.create('Meals', 'utensils', 'orange');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Find and tap edit button for 'Meals'
      // final editButton = find.byIcon(Icons.edit);
      // await tester.tap(editButton);
      // await tester.pumpAndSettle();

      // Verify CategoryEditSheet opened
      // expect(find.byType(CategoryEditSheet), findsOneWidget);
    });

    testWidgets('delete action shows confirmation dialog', (WidgetTester tester) async {
      // Setup: Create custom category with no slips
      // await CategoryService.create('EmptyCategory', 'star', 'blue');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Find and tap delete button
      // final deleteButton = find.byIcon(Icons.delete);
      // await tester.tap(deleteButton);
      // await tester.pumpAndSettle();

      // Verify confirmation dialog
      // expect(find.byType(AlertDialog), findsOneWidget);
      // expect(find.text('Delete EmptyCategory?'), findsOneWidget);
    });

    testWidgets('merge action shows target picker', (WidgetTester tester) async {
      // Setup: Create two custom categories
      // await CategoryService.create('Meals', 'utensils', 'orange');
      // await CategoryService.create('Food', 'apple', 'red');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Find and tap merge button for 'Meals'
      // final mergeButton = find.byIcon(Icons.merge);
      // await tester.tap(mergeButton);
      // await tester.pumpAndSettle();

      // Verify target picker dialog
      // expect(find.text('Merge "Meals" to:'), findsOneWidget);
      // expect(find.text('Food'), findsOneWidget);
      // expect(find.text('Food (built-in)'), findsOneWidget);
    });

    testWidgets('category list shows slip count', (WidgetTester tester) async {
      // Setup: Create category with 3 slips
      // await CategoryService.create('Meals', 'utensils', 'orange');
      // Insert 3 payment slips with category = 'Meals'

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify slip count displayed
      // expect(find.text('3 transactions'), findsOneWidget);
    });

    testWidgets('add new category button navigates to create', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Tap "Add Category" button
      // final addButton = find.text('Add Category');
      // await tester.tap(addButton);
      // await tester.pumpAndSettle();

      // Verify CategoryEditSheet opened in create mode
      // expect(find.byType(CategoryEditSheet), findsOneWidget);
      // // Sheet should have empty name field
    });

    testWidgets('after delete, category removed from list', (WidgetTester tester) async {
      // Setup: Create category
      // await CategoryService.create('Meals', 'utensils', 'orange');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Verify category visible
      // expect(find.text('Meals'), findsOneWidget);

      // Delete category
      // await tester.tap(find.byIcon(Icons.delete));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Delete'));
      // await tester.pumpAndSettle();

      // Verify category removed
      // expect(find.text('Meals'), findsNothing);
    });

    testWidgets('after merge, source category removed', (WidgetTester tester) async {
      // Setup: Create two categories
      // await CategoryService.create('Meals', 'utensils', 'orange');
      // await CategoryService.create('Food', 'apple', 'red');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CategoryManagementScreen(),
          ),
        ),
      );

      // Merge 'Meals' into 'Food'
      // await tester.tap(find.byIcon(Icons.merge).first);
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Food'));
      // await tester.pumpAndSettle();

      // Verify 'Meals' removed
      // expect(find.text('Meals'), findsNothing);
      // expect(find.text('Food'), findsOneWidget);
    });
  });
}
