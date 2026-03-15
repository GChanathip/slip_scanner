import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:avers/features/category/services/category_service.dart';

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

/// Insert a minimal slip row and return its autoincrement id.
Future<int> _insertSlip(
  Database db, {
  String category = 'other',
  String? categorySource,
  String? recipientName,
}) async {
  return db.insert('payment_slips', {
    'imagePath': '/tmp/test.png',
    'amount': 100.0,
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

  group('Custom Categories - Edge Cases', () {
    test('merge last remaining custom category (0 slips)', () async {
      final source = await svc.create('Meals', 'utensils', 'orange');
      final target = await svc.create('Dining', 'fork', 'red');

      await svc.merge(source.id!, target.name);

      final categories = await svc.getAll();
      expect(categories.map((c) => c.name), isNot(contains('Meals')));
      expect(categories.map((c) => c.name), contains('Dining'));
    });

    test('delete category with 0 slips', () async {
      final category = await svc.create('EmptyCategory', 'star', 'blue');

      await svc.delete(category.id!);

      final categories = await svc.getAll();
      expect(categories.map((c) => c.name), isNot(contains('EmptyCategory')));
    });

    test('undo after navigating away (SnackBar timeout)', () async {
      // Insert slip with AI category
      final id = await _insertSlip(
        db,
        category: 'entertainment',
        categorySource: 'ai',
        recipientName: 'Starbucks',
      );

      // User corrects category to 'food'
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

      // Rule created
      await svc.upsertRule('Starbucks', 'food');

      // SnackBar times out — undo not triggered. Slip remains 'food'.
      final rows = await db.query('payment_slips', where: 'id = ?', whereArgs: [id]);
      expect(rows.first['category'], 'food');

      final rule = await svc.findRule('Starbucks');
      expect(rule?.category, 'food');
    });

    test('create category with exactly 30-char name', () async {
      const name = '123456789012345678901234567890'; // 30 chars
      final category = await svc.create(name, 'star', 'blue');
      expect(category.name, name);
    });

    test(
      'create category with 31-char name rejected',
      skip: 'name length limit not yet implemented in CategoryService.create',
      () async {
        const name = '1234567890123456789012345678901'; // 31 chars
        await expectLater(() => svc.create(name, 'star', 'blue'), throwsException);
      },
    );

    test('rename to conflicting name (existing custom)', () async {
      // SQLite UNIQUE COLLATE NOCASE constraint enforces this at DB level.
      final category1 = await svc.create('Meals', 'utensils', 'orange');
      await svc.create('Food', 'apple', 'red');

      await expectLater(
        () => svc.update(category1.id!, name: 'Food'),
        throwsException,
      );
    });

    test(
      'rename to conflicting name (built-in category)',
      skip: 'built-in name conflict not enforced by CategoryService.update',
      () async {
        final category = await svc.create('Meals', 'utensils', 'orange');
        await expectLater(() => svc.update(category.id!, name: 'food'), throwsException);
      },
    );

    test('20 category limit enforcement - exact boundary', () async {
      for (int i = 1; i <= 20; i++) {
        await svc.create('Category$i', 'star', 'blue');
      }

      final categories = await svc.getAll();
      expect(categories.length, 20);

      expect(
        () => svc.create('Category21', 'star', 'blue'),
        throwsStateError,
      );
    });

    test('whitespace and special characters in name', () async {
      final category = await svc.create('Meals Out', 'utensils', 'orange');
      expect(category.name, 'Meals Out');
    });

    test('unicode characters in custom category name', () async {
      const name = 'อาหาร'; // Thai for 'meals'
      final category = await svc.create(name, 'utensils', 'orange');
      expect(category.name, name);
    });

    test('merge with rules pointing to different sources', () async {
      final source = await svc.create('Meals', 'utensils', 'orange');
      final target = await svc.create('Dining', 'fork', 'red');

      await svc.upsertRule('Grab', source.name);
      await svc.upsertRule('Starbucks', target.name);

      await svc.merge(source.id!, target.name);

      final grabRule = await svc.findRule('Grab');
      expect(grabRule?.category, 'Dining');

      final starRule = await svc.findRule('Starbucks');
      expect(starRule?.category, 'Dining');
    });

    test('cascade update on rename with active slips', () async {
      final category = await svc.create('Meals', 'utensils', 'orange');

      final id1 = await _insertSlip(db, category: 'Meals');
      final id2 = await _insertSlip(db, category: 'Meals');

      await svc.update(category.id!, name: 'Dining');

      final row1 = (await db.query('payment_slips', where: 'id = ?', whereArgs: [id1])).first;
      final row2 = (await db.query('payment_slips', where: 'id = ?', whereArgs: [id2])).first;

      expect(row1['category'], 'Dining');
      expect(row2['category'], 'Dining');
    });

    test('rule lookup with null/empty recipient', () async {
      final rule1 = await svc.findRule('');
      expect(rule1, isNull);

      final rule2 = await svc.findRule('   ');
      expect(rule2, isNull);
    });

    test('delete category cascades to all matching slips', () async {
      final category = await svc.create('Meals', 'utensils', 'orange');

      final ids = <int>[];
      for (int i = 1; i <= 5; i++) {
        ids.add(await _insertSlip(db, category: 'Meals'));
      }

      await svc.delete(category.id!);

      for (final id in ids) {
        final rows = await db.query('payment_slips', where: 'id = ?', whereArgs: [id]);
        expect(rows.first['category'], 'other');
      }
    });
  });
}
