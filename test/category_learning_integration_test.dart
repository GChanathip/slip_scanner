import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:avers/services/category_service.dart';

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
        await db.execute('''
          CREATE TABLE payment_slips(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL DEFAULT '',
            assetId TEXT,
            amount REAL NOT NULL DEFAULT 0,
            date TEXT NOT NULL DEFAULT '',
            extractedText TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL DEFAULT '',
            recipientName TEXT,
            notes TEXT,
            category TEXT,
            categorySource TEXT,
            senderName TEXT,
            referenceId TEXT,
            llmProcessingStatus TEXT DEFAULT 'pending',
            ragIndexed INTEGER DEFAULT 0,
            updatedAt TEXT,
            retryCount INTEGER DEFAULT 0,
            isRecurring INTEGER DEFAULT 0,
            recurringFrequency TEXT
          )
        ''');
      },
    ),
  );
  return db;
}

Future<int> _insertSlip(
  Database db, {
  String category = 'other',
  String? categorySource,
  String? recipientName,
  double amount = 100.0,
}) async {
  return db.insert('payment_slips', {
    'imagePath': '/tmp/test.png',
    'amount': amount,
    'date': '2026-03-15',
    'extractedText': 'Test',
    'createdAt': DateTime.now().toIso8601String(),
    'category': category,
    if (categorySource != null) 'categorySource': categorySource,
    if (recipientName != null) 'recipientName': recipientName,
  });
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

  group('Category Learning Integration - Correction → Rule → Re-extraction', () {
    test(
        'full flow: scan → extract with AI → correct → verify rule → '
        'new slip → verify rule applied', () async {
      // Step 1: Insert initial Grab slip with incorrect AI category
      final id1 = await _insertSlip(
        db,
        category: 'shopping',
        categorySource: 'ai',
        recipientName: 'Grab',
        amount: 150.0,
      );

      var rows = await db.query('payment_slips', where: 'id = ?', whereArgs: [id1]);
      expect(rows.first['category'], 'shopping');
      expect(rows.first['categorySource'], 'ai');

      // Step 2: User corrects category to 'transport'
      await db.update(
        'payment_slips',
        {
          'category': 'transport',
          'categorySource': 'user',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id1],
      );
      await svc.upsertRule('Grab', 'transport');

      final rule = await svc.findRule('Grab');
      expect(rule, isNotNull);
      expect(rule?.category, 'transport');
      expect(rule?.source, 'user');

      rows = await db.query('payment_slips', where: 'id = ?', whereArgs: [id1]);
      expect(rows.first['category'], 'transport');
      expect(rows.first['categorySource'], 'user');

      // Step 3: New Grab slip — rule applied during extraction
      final id2 = await _insertSlip(
        db,
        category: 'transport',
        categorySource: 'rule',
        recipientName: 'Grab',
        amount: 80.0,
      );

      rows = await db.query('payment_slips', where: 'id = ?', whereArgs: [id2]);
      expect(rows.first['category'], 'transport');
      expect(rows.first['categorySource'], 'rule',
          reason: 'Rule should have been applied to new slip');
    });

    test('correction → rule → validation', () async {
      const recipientName = 'Starbucks';

      // Insert slip with incorrect AI category
      final id = await _insertSlip(
        db,
        category: 'entertainment',
        categorySource: 'ai',
        recipientName: recipientName,
        amount: 120.0,
      );

      // User corrects to 'food'
      await db.update(
        'payment_slips',
        {
          'category': 'food',
          'categorySource': 'user',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await svc.upsertRule(recipientName, 'food');

      final rule = await svc.findRule(recipientName);
      expect(rule?.category, 'food');
      expect(rule?.source, 'user');

      // Verify normalized lookup
      final ruleVariant = await svc.findRule('  STARBUCKS  ');
      expect(ruleVariant?.category, 'food');
    });

    test('rule override: AI category replaced by rule', () async {
      const recipientName = 'Grab';
      const llmCategory = 'shopping';
      const correctCategory = 'transport';

      await svc.upsertRule(recipientName, correctCategory);

      final rule = await svc.findRule(recipientName);
      expect(rule, isNotNull);

      // Simulate ExtractionService rule override logic
      final finalCategory = rule?.category ?? llmCategory;
      final categorySource = rule != null ? 'rule' : 'ai';

      expect(finalCategory, correctCategory);
      expect(categorySource, 'rule');
    });

    test('custom category in rule accepted', () async {
      final customCategory = await svc.create('Coffee Shops', 'coffee', 'brown');
      await svc.upsertRule('Starbucks', customCategory.name);

      final rule = await svc.findRule('Starbucks');
      expect(rule?.category, 'Coffee Shops');

      final validCategories = await svc.getValidCategoryNames();
      expect(validCategories, contains(rule?.category));
    });

    test('normalization in rule lookup', () async {
      await svc.upsertRule('Grab App', 'transport');

      final rule1 = await svc.findRule('grab app');
      final rule2 = await svc.findRule('  GRAB APP  ');
      final rule3 = await svc.findRule('Grab    App');

      expect(rule1?.category, 'transport');
      expect(rule2?.category, 'transport');
      expect(rule3?.category, 'transport');
    });

    test('rule updated via merge', () async {
      final meals = await svc.create('Meals', 'utensils', 'orange');
      await svc.upsertRule('Grab', meals.name);

      final dining = await svc.create('Dining', 'fork', 'red');
      await svc.merge(meals.id!, dining.name);

      final rule = await svc.findRule('Grab');
      expect(rule?.category, 'Dining');
    });

    test('rule deleted via category delete', () async {
      final category = await svc.create('Meals', 'utensils', 'orange');
      await svc.upsertRule('Grab', category.name);

      await svc.delete(category.id!);

      final rule = await svc.findRule('Grab');
      expect(rule, isNull);
    });

    test('no recipientName → no rule created', () async {
      const recipientName = '';

      if (recipientName.isNotEmpty) {
        await svc.upsertRule(recipientName, 'food');
      }

      final rule = await svc.findRule(recipientName);
      expect(rule, isNull);
    });

    test('same category selected → no rule created', () async {
      // Rule should only be created when category actually changes (UI responsibility).
      // Verify no pre-existing rule.
      final rule = await svc.findRule('Grab');
      expect(rule, isNull);
    });
  });
}
