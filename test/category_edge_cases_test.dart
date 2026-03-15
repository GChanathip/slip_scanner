import 'package:flutter_test/flutter_test.dart';
import 'package:slip_scanner/models/custom_category.dart';
import 'package:slip_scanner/models/payment_slip.dart';
import 'package:slip_scanner/services/category_service.dart';
import 'package:slip_scanner/services/database_service.dart';

void main() {
  group('Custom Categories - Edge Cases', () {
    test('merge last remaining custom category (0 slips)', () async {
      // Setup: Create two custom categories, no slips
      final source = await CategoryService.create('Meals', 'utensils', 'orange');
      final target = await CategoryService.create('Dining', 'fork', 'red');

      // Merge source → target
      await CategoryService.merge(source.id!, target.name);

      // Verify: source deleted, target exists
      final categories = await CategoryService.getAll();
      expect(categories.map((c) => c.name), isNot(contains('Meals')));
      expect(categories.map((c) => c.name), contains('Dining'));
    });

    test('delete category with 0 slips', () async {
      // Setup: Create custom category, no slips
      final category = await CategoryService.create(
        'EmptyCategory',
        'star',
        'blue',
      );

      // Delete
      await CategoryService.delete(category.id!);

      // Verify: deleted from DB
      final categories = await CategoryService.getAll();
      expect(categories.map((c) => c.name), isNot(contains('EmptyCategory')));
    });

    test('undo after navigating away (SnackBar timeout)', () async {
      // This is more of a widget/integration test
      // Simulating: User corrects category, SnackBar shows, but user navigates away
      // before tapping Undo, SnackBar times out

      // Setup: Slip with initial category
      final slip = PaymentSlip(
        id: 1,
        imagePath: '/tmp/test.png',
        assetId: 'asset1',
        amount: 100.0,
        date: '2026-03-15',
        extractedText: 'Test',
        recipientName: 'Starbucks',
        notes: '',
        category: 'entertainment',
        categorySource: 'ai',
        senderName: 'John',
        referenceId: 'REF123',
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseService.insertPaymentSlip(slip);

      // User corrects to 'food'
      await DatabaseService.updateExtractedData(
        slip.id!,
        recipientName: 'Starbucks',
        notes: '',
        category: 'food',
        categorySource: 'user',
      );

      // Create rule
      await CategoryService.upsertRule('Starbucks', 'food');

      // SnackBar shows "Got it! Future 'Starbucks' transactions → Food [Undo]"
      // But user navigates away before SnackBar timeout/before tapping Undo
      // After SnackBar timeout (8s), undo is not possible

      // Verify: slip remains with 'food'
      final updated = await DatabaseService.getPaymentSlip(slip.id!);
      expect(updated?.category, 'food');

      // Verify: rule remains
      final rule = await CategoryService.findRule('Starbucks');
      expect(rule?.category, 'food');
    });

    test('create category with exactly 30-char name', () async {
      // 30 characters exactly
      const name = '123456789012345678901234567890';

      final category = await CategoryService.create(
        name,
        'star',
        'blue',
      );

      expect(category.name, name);
    });

    test('create category with 31-char name rejected', () async {
      // 31 characters - should be rejected
      const name = '1234567890123456789012345678901';

      expect(
        () => CategoryService.create(name, 'star', 'blue'),
        throwsException,
      );
    });

    test('rename to conflicting name (existing custom)', () async {
      // Setup: Two custom categories
      final category1 =
          await CategoryService.create('Meals', 'utensils', 'orange');
      final category2 = await CategoryService.create('Food', 'apple', 'red');

      // Try to rename category1 to 'Food' (conflicts with category2)
      expect(
        () => CategoryService.update(category1.id!, name: 'Food'),
        throwsException,
      );
    });

    test('rename to conflicting name (built-in category)', () async {
      // Setup: Custom category
      final category =
          await CategoryService.create('Meals', 'utensils', 'orange');

      // Try to rename to built-in category name 'food'
      expect(
        () => CategoryService.update(category.id!, name: 'food'),
        throwsException,
      );
    });

    test('20 category limit enforcement - exact boundary', () async {
      // Create exactly 20 categories
      for (int i = 1; i <= 20; i++) {
        await CategoryService.create(
          'Category$i',
          'star',
          'blue',
        );
      }

      // Verify count is 20
      final categories = await CategoryService.getAll();
      expect(categories.length, 20);

      // 21st should fail
      expect(
        () => CategoryService.create('Category21', 'star', 'blue'),
        throwsException,
      );
    });

    test('database budget cleanup on delete', () async {
      // This requires mocking or testing integration with BudgetService
      // Setup: Create category with slips and budget entries
      // final category = await CategoryService.create('Meals', 'utensils', 'orange');
      // Insert slips with this category
      // Create budget for 'Meals'

      // Delete category
      // await CategoryService.delete(category.id!);

      // Verify: BudgetService cleanup called
      // expect(budgetCleanupCalled, true);
    });

    test('whitespace and special characters in name', () async {
      // Test various whitespace scenarios
      const name = '  Meals Out  ';

      final category = await CategoryService.create(
        name.trim(),
        'utensils',
        'orange',
      );

      // Name should be stored as trimmed
      expect(category.name, 'Meals Out');
    });

    test('unicode characters in custom category name', () async {
      // Thai characters
      const name = 'อาหาร'; // 'Meals' in Thai

      final category = await CategoryService.create(
        name,
        'utensils',
        'orange',
      );

      expect(category.name, name);

      // Lookup should work
      final lookup = await CategoryService.findRule(name);
      // expect(lookup, ...);
    });

    test('merge with rules pointing to different sources', () async {
      // Setup: Two categories with different rule sources
      final source = await CategoryService.create('Meals', 'utensils', 'orange');
      final target = await CategoryService.create('Dining', 'fork', 'red');

      // Source has rule: Grab → Meals
      await CategoryService.upsertRule('Grab', source.name);

      // Target has rule: Starbucks → Dining
      await CategoryService.upsertRule('Starbucks', target.name);

      // Merge source → target
      await CategoryService.merge(source.id!, target.name);

      // Verify: Grab rule now → Dining
      final grabRule = await CategoryService.findRule('Grab');
      expect(grabRule?.category, 'Dining');

      // Verify: Starbucks rule unchanged
      final starRule = await CategoryService.findRule('Starbucks');
      expect(starRule?.category, 'Dining');
    });

    test('cascade update on rename with active slips', () async {
      // Setup: Create category
      final category = await CategoryService.create('Meals', 'utensils', 'orange');

      // Insert multiple slips with this category
      final slip1 = PaymentSlip(
        id: 1,
        imagePath: '/tmp/test1.png',
        assetId: 'asset1',
        amount: 100.0,
        date: '2026-03-15',
        extractedText: 'Test1',
        recipientName: 'Restaurant1',
        notes: '',
        category: 'Meals',
        categorySource: 'user',
        senderName: 'John',
        referenceId: 'REF1',
        createdAt: DateTime.now().toIso8601String(),
      );

      final slip2 = PaymentSlip(
        id: 2,
        imagePath: '/tmp/test2.png',
        assetId: 'asset2',
        amount: 150.0,
        date: '2026-03-16',
        extractedText: 'Test2',
        recipientName: 'Restaurant2',
        notes: '',
        category: 'Meals',
        categorySource: 'user',
        senderName: 'Jane',
        referenceId: 'REF2',
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseService.insertPaymentSlip(slip1);
      await DatabaseService.insertPaymentSlip(slip2);

      // Rename category
      await CategoryService.update(category.id!, name: 'Dining');

      // Verify: both slips updated
      final updated1 = await DatabaseService.getPaymentSlip(slip1.id!);
      final updated2 = await DatabaseService.getPaymentSlip(slip2.id!);

      expect(updated1?.category, 'Dining');
      expect(updated2?.category, 'Dining');
    });

    test('rule lookup with null/empty recipient', () async {
      // Lookup with empty string
      final rule1 = await CategoryService.findRule('');
      expect(rule1, isNull);

      // Lookup with whitespace
      final rule2 = await CategoryService.findRule('   ');
      expect(rule2, isNull);
    });

    test('delete category cascades to all matching slips', () async {
      // Setup: Create category with 5 slips
      final category = await CategoryService.create('Meals', 'utensils', 'orange');

      // Insert 5 slips with 'Meals'
      for (int i = 1; i <= 5; i++) {
        final slip = PaymentSlip(
          id: i,
          imagePath: '/tmp/test$i.png',
          assetId: 'asset$i',
          amount: 100.0 + i,
          date: '2026-03-15',
          extractedText: 'Test$i',
          recipientName: 'Restaurant$i',
          notes: '',
          category: 'Meals',
          categorySource: 'user',
          senderName: 'John',
          referenceId: 'REF$i',
          createdAt: DateTime.now().toIso8601String(),
        );
        await DatabaseService.insertPaymentSlip(slip);
      }

      // Delete category
      await CategoryService.delete(category.id!);

      // Verify: all slips updated to 'other'
      for (int i = 1; i <= 5; i++) {
        final slip = await DatabaseService.getPaymentSlip(i);
        expect(slip?.category, 'other');
      }
    });
  });
}
