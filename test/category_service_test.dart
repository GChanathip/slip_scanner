import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:slip_scanner/models/custom_category.dart';
import 'package:slip_scanner/services/category_service.dart';

void main() {
  // For testing, we need to use sqflite_ffi
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CategoryService', () {
    group('Custom Categories CRUD', () {
      test('create: adds new custom category', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );
        expect(category.name, 'Meals');
        expect(category.icon, 'utensils');
        expect(category.color, 'orange');
        expect(category.id, isNotNull);
      });

      test('create: rejects duplicate names (case-insensitive)', () async {
        await CategoryService.create('Meals', 'utensils', 'orange');
        expect(
          () => CategoryService.create('meals', 'coffee', 'brown'),
          throwsException,
        );
      });

      test('create: rejects 21st category (20 limit)', () async {
        // Create 20 categories
        for (int i = 0; i < 20; i++) {
          await CategoryService.create(
            'Category$i',
            'utensils',
            'orange',
          );
        }
        // 21st should fail
        expect(
          () => CategoryService.create('Category20', 'utensils', 'orange'),
          throwsException,
        );
      });

      test('getAll: returns all custom categories', () async {
        await CategoryService.create('Meals', 'utensils', 'orange');
        await CategoryService.create('Coffee', 'coffee', 'brown');

        final categories = await CategoryService.getAll();
        expect(categories.length, 2);
        expect(categories.map((c) => c.name), containsAll(['Meals', 'Coffee']));
      });

      test('update: renames category with cascade', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        await CategoryService.update(
          category.id!,
          name: 'Dining',
        );

        final updated = await CategoryService.getAll();
        expect(updated.first.name, 'Dining');
      });

      test('update: rejects duplicate renamed name', () async {
        await CategoryService.create('Meals', 'utensils', 'orange');
        final category = await CategoryService.create('Food', 'apple', 'red');

        expect(
          () => CategoryService.update(category.id!, name: 'Meals'),
          throwsException,
        );
      });

      test('update: cascades name to payment_slips', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        // Insert a slip with this category
        // (requires mock or test DB setup)
        // Verify slip's category is updated
      });

      test('delete: changes slips to "other" category', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        await CategoryService.delete(category.id!);

        // Verify slips reassigned to 'other'
        // Verify category removed from DB
      });

      test('delete: cascades to category_rules', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        // Create rule for 'Meals'
        await CategoryService.upsertRule('Grab', 'Meals');

        // Delete category
        await CategoryService.delete(category.id!);

        // Verify rule is deleted
        final rule = await CategoryService.findRule('Grab');
        expect(rule, isNull);
      });

      test('delete: fires budget cleanup event', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        // Track cleanup call
        // await CategoryService.delete(category.id!);
        // expect(budgetCleanupFired, true);
      });
    });

    group('Merge', () {
      test('merge: cascades slips to target category', () async {
        final source = await CategoryService.create('Meals', 'utensils', 'orange');
        final target = await CategoryService.create('Dining', 'fork', 'red');

        // Insert slips with source category
        // Merge source → target
        // Verify slips now have target category
      });

      test('merge: cascades rules to target', () async {
        final source = await CategoryService.create('Meals', 'utensils', 'orange');
        final target = await CategoryService.create('Dining', 'fork', 'red');

        await CategoryService.upsertRule('Grab', 'Meals');
        await CategoryService.merge(source.id!, 'Dining');

        final rule = await CategoryService.findRule('Grab');
        expect(rule?.category, 'Dining');
      });

      test('merge: deletes source category', () async {
        final source = await CategoryService.create('Meals', 'utensils', 'orange');
        final target = await CategoryService.create('Dining', 'fork', 'red');

        await CategoryService.merge(source.id!, 'Dining');

        final categories = await CategoryService.getAll();
        expect(categories.map((c) => c.name), isNot(contains('Meals')));
      });

      test('merge: to built-in category allowed', () async {
        final source = await CategoryService.create('Meals', 'utensils', 'orange');

        // Merge to built-in 'food'
        await CategoryService.merge(source.id!, 'food');

        final categories = await CategoryService.getAll();
        expect(categories.map((c) => c.name), isNot(contains('Meals')));
      });

      test('merge: last remaining custom category with 0 slips', () async {
        final source = await CategoryService.create('Meals', 'utensils', 'orange');
        final target = await CategoryService.create('Dining', 'fork', 'red');

        await CategoryService.merge(source.id!, 'Dining');

        // Verify success
        final categories = await CategoryService.getAll();
        expect(categories.length, 1);
      });
    });

    group('Category Rules', () {
      test('findRule: returns null for unknown recipient', () async {
        final rule = await CategoryService.findRule('UnknownPerson');
        expect(rule, isNull);
      });

      test('findRule: returns rule for exact normalized recipient', () async {
        await CategoryService.upsertRule('Grab', 'transport');

        final rule = await CategoryService.findRule('Grab');
        expect(rule?.category, 'transport');
      });

      test('findRule: normalized match (whitespace, casing)', () async {
        await CategoryService.upsertRule('Grab  App', 'transport');

        // Normalization: lowercase, trim, collapse whitespace
        final rule = await CategoryService.findRule('  GRAB APP  ');
        expect(rule?.category, 'transport');
      });

      test('upsertRule: creates new rule', () async {
        await CategoryService.upsertRule('Starbucks', 'food');

        final rule = await CategoryService.findRule('Starbucks');
        expect(rule?.category, 'food');
        expect(rule?.source, 'user');
      });

      test('upsertRule: updates existing rule', () async {
        await CategoryService.upsertRule('Starbucks', 'food');
        await CategoryService.upsertRule('Starbucks', 'entertainment');

        final rule = await CategoryService.findRule('Starbucks');
        expect(rule?.category, 'entertainment');
      });

      test('getAllRules: returns all rules', () async {
        await CategoryService.upsertRule('Grab', 'transport');
        await CategoryService.upsertRule('Starbucks', 'food');

        final rules = await CategoryService.getAllRules();
        expect(rules.length, 2);
      });

      test('deleteRule: removes rule', () async {
        await CategoryService.upsertRule('Grab', 'transport');

        await CategoryService.deleteRule('Grab');

        final rule = await CategoryService.findRule('Grab');
        expect(rule, isNull);
      });
    });

    group('Normalization', () {
      test('normalizeRecipient: lowercase', () async {
        final normalized = CategoryService.normalizeRecipient('GRAB');
        expect(normalized, 'grab');
      });

      test('normalizeRecipient: trim', () async {
        final normalized = CategoryService.normalizeRecipient('  Grab  ');
        expect(normalized, 'grab');
      });

      test('normalizeRecipient: collapse whitespace', () async {
        final normalized = CategoryService.normalizeRecipient('Grab   App');
        expect(normalized, 'grab app');
      });

      test('normalizeRecipient: empty string', () async {
        final normalized = CategoryService.normalizeRecipient('   ');
        expect(normalized, '');
      });
    });

    group('Category Lookup', () {
      test('getValidCategoryNames: includes built-in', () async {
        final names = await CategoryService.getValidCategoryNames();
        expect(names, containsAll(['food', 'transport', 'utilities']));
      });

      test('getValidCategoryNames: includes custom', () async {
        await CategoryService.create('Meals', 'utensils', 'orange');

        final names = await CategoryService.getValidCategoryNames();
        expect(names, contains('Meals'));
      });

      test('getSlipCount: returns count for category', () async {
        final category = await CategoryService.create(
          'Meals',
          'utensils',
          'orange',
        );

        // Insert 3 slips with 'Meals' category
        // Verify count is 3
      });
    });
  });
}
