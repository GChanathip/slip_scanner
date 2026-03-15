import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:slip_scanner/services/category_service.dart';

// ─── Minimal v7 schema (only tables CategoryService touches) ─────────────────

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
        await db.execute(
          'CREATE INDEX idx_cr_cat ON category_rules(category)',
        );
        await db.execute('''
          CREATE TABLE payment_slips(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL DEFAULT '',
            amount REAL NOT NULL DEFAULT 0,
            date TEXT NOT NULL DEFAULT '',
            extractedText TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL DEFAULT '',
            category TEXT,
            llmProcessingStatus TEXT DEFAULT 'pending'
          )
        ''');
      },
    ),
  );
  return db;
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

Future<void> _insertSlip(Database db, {String? category}) =>
    db.insert('payment_slips', {
      'imagePath': '',
      'amount': 10.0,
      'date': '',
      'extractedText': '',
      'createdAt': DateTime.now().toIso8601String(),
      if (category != null) 'category': category,
    });

void main() {
  setUpAll(() => sqfliteFfiInit());

  late Database db;
  late CategoryService svc;

  setUp(() async {
    db = await _openTestDb();
    svc = CategoryService(db);
  });

  tearDown(() => db.close());

  // ─── Custom category CRUD ─────────────────────────────────────────────────

  group('create', () {
    test('returns new category with id', () async {
      final cat = await svc.create('Dining', 'utensils', 'orange');
      expect(cat.id, isNotNull);
      expect(cat.name, 'Dining');
      expect(cat.icon, 'utensils');
      expect(cat.color, 'orange');
    });

    test('trims whitespace from name', () async {
      final cat = await svc.create('  Coffee  ', 'coffee', 'orange');
      expect(cat.name, 'Coffee');
    });

    test('rejects case-insensitive duplicate', () async {
      await svc.create('Coffee', 'coffee', 'orange');
      await expectLater(
        () => svc.create('coffee', 'coffee', 'orange'),
        throwsArgumentError,
      );
      await expectLater(
        () => svc.create('COFFEE', 'coffee', 'orange'),
        throwsArgumentError,
      );
    });

    test('enforces 20-category limit', () async {
      for (var i = 0; i < 20; i++) {
        await svc.create('Cat$i', 'utensils', 'orange');
      }
      await expectLater(
        () => svc.create('Cat20', 'utensils', 'orange'),
        throwsStateError,
      );
    });
  });

  group('getAll', () {
    test('returns empty list initially', () async {
      expect(await svc.getAll(), isEmpty);
    });

    test('returns categories ordered by name', () async {
      await svc.create('Zebra', 'utensils', 'orange');
      await svc.create('Alpha', 'utensils', 'orange');
      await svc.create('Mango', 'utensils', 'orange');
      final names = (await svc.getAll()).map((c) => c.name).toList();
      expect(names, ['Alpha', 'Mango', 'Zebra']);
    });
  });

  group('update', () {
    test('renames category and cascades to payment_slips', () async {
      final cat = await svc.create('OldName', 'utensils', 'orange');
      await _insertSlip(db, category: 'OldName');

      await svc.update(cat.id!, name: 'NewName');

      final slip = (await db.query('payment_slips')).first;
      expect(slip['category'], 'NewName');

      final updated = await svc.getAll();
      expect(updated.first.name, 'NewName');
    });

    test('renames category and cascades to category_rules', () async {
      final cat = await svc.create('OldName', 'utensils', 'orange');
      await db.insert('category_rules', {
        'recipientPattern': 'some shop',
        'category': 'OldName',
        'source': 'user',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await svc.update(cat.id!, name: 'NewName');

      final rule = (await db.query('category_rules')).first;
      expect(rule['category'], 'NewName');
    });

    test('updates icon/color without rename cascade', () async {
      final cat = await svc.create('Stable', 'utensils', 'orange');
      await _insertSlip(db, category: 'Stable');

      await svc.update(cat.id!, icon: 'coffee', color: 'brown');

      final slip = (await db.query('payment_slips')).first;
      expect(slip['category'], 'Stable'); // unchanged
    });

    test('no-op when no fields provided', () async {
      final cat = await svc.create('Stable', 'utensils', 'orange');
      await svc.update(cat.id!);
      expect((await svc.getAll()).first.name, 'Stable');
    });
  });

  group('delete', () {
    test('cascades slips to "other" and removes category', () async {
      final cat = await svc.create('Fancy', 'utensils', 'orange');
      await _insertSlip(db, category: 'Fancy');

      await svc.delete(cat.id!);

      expect(await svc.getAll(), isEmpty);
      final slip = (await db.query('payment_slips')).first;
      expect(slip['category'], 'other');
    });

    test('removes associated category_rules', () async {
      final cat = await svc.create('Niche', 'utensils', 'orange');
      await svc.upsertRule('niche shop', 'Niche');

      await svc.delete(cat.id!);

      expect(await svc.getAllRules(), isEmpty);
    });

    test('is a no-op for non-existent id', () async {
      await svc.delete(9999); // must not throw
    });
  });

  // ─── Merge ────────────────────────────────────────────────────────────────

  group('merge', () {
    test('cascades slips and rules to target, removes source', () async {
      final src = await svc.create('Snacks', 'utensils', 'orange');
      await _insertSlip(db, category: 'Snacks');
      await svc.upsertRule('snack bar', 'Snacks');

      await svc.merge(src.id!, 'food');

      expect(await svc.getAll(), isEmpty);
      final slip = (await db.query('payment_slips')).first;
      expect(slip['category'], 'food');
      final rule = (await svc.getAllRules()).first;
      expect(rule.category, 'food');
    });

    test('merge to built-in category', () async {
      final src = await svc.create('Meals', 'utensils', 'orange');
      await svc.merge(src.id!, 'food');
      expect(await svc.getAll(), isEmpty);
    });

    test('merge to custom target category', () async {
      final src = await svc.create('Snacks', 'utensils', 'orange');
      final target = await svc.create('Dining', 'fork', 'red');
      await _insertSlip(db, category: 'Snacks');

      await svc.merge(src.id!, target.name);

      final slip = (await db.query('payment_slips')).first;
      expect(slip['category'], 'Dining');
      final remaining = (await svc.getAll()).map((c) => c.name).toList();
      expect(remaining, ['Dining']);
    });

    test('throws for unknown source id', () async {
      await expectLater(() => svc.merge(9999, 'food'), throwsArgumentError);
    });
  });

  // ─── Category rules ───────────────────────────────────────────────────────

  group('upsertRule / findRule', () {
    test('stores and retrieves a rule', () async {
      await svc.upsertRule('7-Eleven', 'shopping');
      final rule = await svc.findRule('7-Eleven');
      expect(rule, isNotNull);
      expect(rule!.category, 'shopping');
      expect(rule.source, 'user');
    });

    test('normalises on upsert and lookup', () async {
      await svc.upsertRule('  Big C  ', 'groceries');
      final rule = await svc.findRule('big c');
      expect(rule, isNotNull);
      expect(rule!.category, 'groceries');
    });

    test('replaces existing rule on conflict', () async {
      await svc.upsertRule('MK Restaurant', 'food');
      await svc.upsertRule('MK Restaurant', 'entertainment');
      final rule = await svc.findRule('MK Restaurant');
      expect(rule!.category, 'entertainment');
    });

    test('returns null for unknown recipient', () async {
      expect(await svc.findRule('Unknown Merchant'), isNull);
    });
  });

  group('deleteRule', () {
    test('removes a rule by pattern', () async {
      await svc.upsertRule('Shop A', 'shopping');
      await svc.deleteRule(svc.normalizeRecipient('Shop A'));
      expect(await svc.findRule('Shop A'), isNull);
    });
  });

  group('getAllRules', () {
    test('returns rules ordered by pattern', () async {
      await svc.upsertRule('Zebra Store', 'shopping');
      await svc.upsertRule('Alpha Café', 'food');
      final patterns = (await svc.getAllRules()).map((r) => r.recipientPattern).toList();
      expect(patterns, ['alpha café', 'zebra store']);
    });
  });

  // ─── normalizeRecipient ───────────────────────────────────────────────────

  group('normalizeRecipient', () {
    test('lowercases, trims, collapses whitespace', () {
      expect(svc.normalizeRecipient('  Hello   World  '), 'hello world');
      expect(svc.normalizeRecipient('STARBUCKS'), 'starbucks');
      expect(svc.normalizeRecipient('A  B  C'), 'a b c');
    });
  });

  // ─── getValidCategoryNames ────────────────────────────────────────────────

  group('getValidCategoryNames', () {
    test('includes built-in slugs', () async {
      final valid = await svc.getValidCategoryNames();
      expect(valid, containsAll(['food', 'transport', 'other']));
    });

    test('includes custom category names', () async {
      await svc.create('MySuperCategory', 'utensils', 'orange');
      final valid = await svc.getValidCategoryNames();
      expect(valid, contains('MySuperCategory'));
    });
  });
}
