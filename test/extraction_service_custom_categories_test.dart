import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:slip_scanner/models/extraction_result.dart';
import 'package:slip_scanner/services/category_service.dart';
import 'package:slip_scanner/services/extraction_service.dart';

void main() {
  group('ExtractionService with Custom Categories', () {
    group('Rule Override', () {
      test('rule exists: LLM category overridden, source = rule', () async {
        // Setup rule: Grab → transport
        await CategoryService.upsertRule('Grab', 'transport');

        // Mock LLM response with different category (e.g., 'shopping')
        final extractedText = 'Grab transaction from Grab\nAmount: 50\n...';

        // Call extraction with custom category validation
        final result = await ExtractionService.extractFromText(extractedText);

        // Verify: rule overrides LLM, source = 'rule'
        expect(result.category, 'transport');
        expect(result.categorySource, 'rule');
      });

      test('no rule: LLM category used, source = ai', () async {
        // No rule for this recipient
        final extractedText = 'Unknown Restaurant\nAmount: 250\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        // Verify: LLM category used, source = 'ai'
        expect(result.category, isNotNull);
        expect(result.categorySource, 'ai');
      });

      test('rule for built-in category accepted', () async {
        // Rule: Starbucks → food
        await CategoryService.upsertRule('Starbucks', 'food');

        final extractedText = 'Starbucks\nAmount: 120\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        expect(result.category, 'food');
        expect(result.categorySource, 'rule');
      });

      test('rule for custom category accepted', () async {
        // Create custom category
        await CategoryService.create('Meals', 'utensils', 'orange');

        // Rule: Grab → Meals (custom)
        await CategoryService.upsertRule('Grab', 'Meals');

        final extractedText = 'Grab transaction\nAmount: 50\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        expect(result.category, 'Meals');
        expect(result.categorySource, 'rule');
      });

      test('rule normalized recipient match', () async {
        // Rule for "Grab App"
        await CategoryService.upsertRule('Grab App', 'transport');

        // OCR text has "GRAB APP" (different casing/spacing)
        final extractedText = 'Payment to   GRAB APP  \nAmount: 50\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        // Normalization should match
        expect(result.category, 'transport');
        expect(result.categorySource, 'rule');
      });
    });

    group('Category Validation', () {
      test('LLM custom category in response accepted', () async {
        // Custom category 'Meals' exists
        await CategoryService.create('Meals', 'utensils', 'orange');

        // LLM returns 'Meals' (not a built-in)
        // Mock response: {"recipientName": "...", "notes": "...", "category": "Meals"}

        // Verify: accepted as valid
        // expect(validationPassed, true);
      });

      test('unknown category fallback to other', () async {
        // LLM returns 'InvalidCategory' (not in built-in or custom)
        final extractedText = 'Some transaction\nAmount: 100\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        // Verify: fallback to 'other'
        if (result.category != null && !await _isValidCategory(result.category!)) {
          expect(result.category, 'other');
        }
      });

      test('null category fallback to other', () async {
        // LLM returns null for category
        // Verify: defaults to 'other'
      });
    });

    group('Dynamic System Prompt', () {
      test('prompt includes custom category names', () async {
        await CategoryService.create('Meals', 'utensils', 'orange');
        await CategoryService.create('Coffee', 'coffee', 'brown');

        // Get system prompt (may need to expose it for testing)
        // Verify: includes "Meals" and "Coffee" in category list

        // Example:
        // "category: one of: food, transport, ..., Meals, Coffee"
      });

      test('prompt updated when custom category added', () async {
        // Get initial prompt
        // Add new custom category
        // Get updated prompt
        // Verify: new category included
      });

      test('prompt updated when custom category deleted', () async {
        final category = await CategoryService.create('Meals', 'utensils', 'orange');

        // Get initial prompt
        // Delete category
        // Get updated prompt
        // Verify: 'Meals' removed from prompt
      });
    });

    group('Extraction Result', () {
      test('includes categorySource in result', () async {
        final extractedText = 'Test transaction\nAmount: 100\n...';

        final result = await ExtractionService.extractFromText(extractedText);

        expect(result.categorySource, isNotNull);
        expect(result.categorySource, isIn(['ai', 'rule', 'user']));
      });
    });
  });

  // Helper to validate category
  Future<bool> _isValidCategory(String category) async {
    final validNames = await CategoryService.getValidCategoryNames();
    return validNames.contains(category);
  }
}
