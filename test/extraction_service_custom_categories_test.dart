/// Unit tests for ExtractionService's rule-based override and category
/// validation logic — no LLM / CactusService involvement.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:avers/features/category/services/category_service.dart';
import 'package:avers/features/extraction/services/extraction_service.dart';

// ─── Minimal in-memory DB (same schema as category_service_test) ─────────────

Future<Database> _openTestDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE custom_categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE COLLATE NOCASE,
            icon TEXT NOT NULL DEFAULT 'utensils',
            color TEXT NOT NULL DEFAULT 'orange',
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE category_rules(
            recipientPattern TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'user',
            createdAt TEXT NOT NULL
          )
        ''');
      },
    ),
  );
  return db;
}

void main() {
  setUpAll(() => sqfliteFfiInit());

  late Database db;
  late CategoryService svc;

  setUp(() async {
    db = await _openTestDb();
    svc = CategoryService(db);
  });

  tearDown(() => db.close());

  // ─── applyRuleOverride ────────────────────────────────────────────────────

  group('applyRuleOverride', () {
    test('rule exists → category overridden, source = rule', () async {
      await svc.upsertRule('Grab', 'transport');
      final base = ExtractionResult(
        recipientName: 'Grab',
        notes: null,
        category: 'shopping', // LLM guessed wrong
      );

      final result = await ExtractionService.applyRuleOverride(base, svc);

      expect(result.category, 'transport');
      expect(result.categorySource, 'rule');
    });

    test('no rule → LLM category preserved, source = ai', () async {
      final base = ExtractionResult(
        recipientName: 'Unknown Restaurant',
        notes: null,
        category: 'food',
      );

      final result = await ExtractionService.applyRuleOverride(base, svc);

      expect(result.category, 'food');
      expect(result.categorySource, 'ai');
    });

    test('rule lookup normalises recipient name', () async {
      await svc.upsertRule('  GRAB APP  ', 'transport');
      final base = ExtractionResult(
        recipientName: 'Grab App', // different casing
        notes: null,
        category: 'shopping',
      );

      final result = await ExtractionService.applyRuleOverride(base, svc);

      expect(result.category, 'transport');
      expect(result.categorySource, 'rule');
    });

    test('rule for custom category accepted', () async {
      await svc.create('Meals', 'utensils', 'orange');
      await svc.upsertRule('MK Restaurant', 'Meals');
      final base = ExtractionResult(
        recipientName: 'MK Restaurant',
        notes: null,
        category: 'food',
      );

      final result = await ExtractionService.applyRuleOverride(base, svc);

      expect(result.category, 'Meals');
      expect(result.categorySource, 'rule');
    });

    test('null recipientName → source = ai, no rule lookup', () async {
      await svc.upsertRule('grab', 'transport');
      final base = ExtractionResult(
        recipientName: null,
        notes: null,
        category: 'other',
      );

      final result = await ExtractionService.applyRuleOverride(base, svc);

      expect(result.categorySource, 'ai');
    });
  });

  // ─── validateCategoryForTest ──────────────────────────────────────────────

  group('validateCategory', () {
    const builtIns = {
      'food', 'transport', 'utilities', 'shopping', 'transfer',
      'entertainment', 'health', 'education', 'rent', 'subscriptions',
      'groceries', 'personal_care', 'gifts', 'other',
    };

    test('valid built-in category returned as-is', () {
      expect(ExtractionService.validateCategoryForTest('food', builtIns), 'food');
      expect(ExtractionService.validateCategoryForTest('transport', builtIns), 'transport');
    });

    test('unknown category falls back to other', () {
      expect(ExtractionService.validateCategoryForTest('invalid_xyz', builtIns), 'other');
    });

    test('null falls back to other', () {
      expect(ExtractionService.validateCategoryForTest(null, builtIns), 'other');
    });

    test('custom category name accepted when in valid set', () {
      final withCustom = {...builtIns, 'Meals'};
      expect(ExtractionService.validateCategoryForTest('Meals', withCustom), 'Meals');
    });

    test('custom category NOT in set falls back to other', () {
      expect(ExtractionService.validateCategoryForTest('Meals', builtIns), 'other');
    });
  });

  // ─── buildSystemPromptForTest ─────────────────────────────────────────────

  group('buildSystemPrompt', () {
    test('includes built-in category names in prompt', () {
      final prompt = ExtractionService.buildSystemPromptForTest(
        {'food', 'transport', 'other'},
      );
      expect(prompt, contains('food'));
      expect(prompt, contains('transport'));
      expect(prompt, contains('other'));
    });

    test('includes custom category names in prompt', () async {
      await svc.create('Meals', 'utensils', 'orange');
      await svc.create('Nightlife', 'utensils', 'purple');
      final validCategories = await svc.getValidCategoryNames();

      final prompt = ExtractionService.buildSystemPromptForTest(validCategories);

      expect(prompt, contains('Meals'));
      expect(prompt, contains('Nightlife'));
    });

    test('prompt changes when custom category added', () async {
      final before = ExtractionService.buildSystemPromptForTest(
        await svc.getValidCategoryNames(),
      );
      await svc.create('NewCat', 'utensils', 'orange');
      final after = ExtractionService.buildSystemPromptForTest(
        await svc.getValidCategoryNames(),
      );

      expect(before, isNot(contains('NewCat')));
      expect(after, contains('NewCat'));
    });
  });
}
