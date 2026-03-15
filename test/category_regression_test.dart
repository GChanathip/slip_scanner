/// Regression tests verifying that adding custom-category support
/// (v7 migration, CategoryService, categorySource) does not break
/// existing behaviour for built-in categories, PaymentSlip model,
/// and OCR field handling.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:avers/models/payment_slip.dart';
import 'package:avers/models/category_registry.dart';
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

void main() {
  setUpAll(() => sqfliteFfiInit());

  late Database db;
  late CategoryService svc;

  setUp(() async {
    db = await _openTestDb();
    svc = CategoryService(db);
  });

  tearDown(() => db.close());

  group('Custom Categories - Regression Tests', () {
    // ── Built-in categories ──────────────────────────────────────────────

    test('all 14 built-in category slugs remain valid', () async {
      const expected = [
        'food', 'transport', 'utilities', 'shopping', 'transfer',
        'entertainment', 'health', 'education', 'rent', 'subscriptions',
        'groceries', 'personal_care', 'gifts', 'other',
      ];
      final validNames = await svc.getValidCategoryNames();
      for (final cat in expected) {
        expect(validNames, contains(cat),
            reason: 'Built-in "$cat" must remain valid after v7');
      }
    });

    test('kBuiltInCategorySlugs has exactly 14 entries', () {
      expect(kBuiltInCategorySlugs, hasLength(14));
    });

    test('kBuiltInCategories registry has matching slugs', () {
      final registrySlugs = kBuiltInCategories.map((c) => c.slug).toSet();
      expect(registrySlugs, containsAll(kBuiltInCategorySlugs));
    });

    // ── PaymentSlip model — categorySource field ─────────────────────────

    test('PaymentSlip.categorySource defaults to null', () {
      final slip = PaymentSlip(
        imagePath: '/tmp/test.png',
        amount: 100.0,
        date: DateTime(2026, 3, 15),
        extractedText: 'Test',
        createdAt: DateTime.now(),
      );
      expect(slip.categorySource, isNull);
    });

    test('PaymentSlip.toMap includes categorySource', () {
      final slip = PaymentSlip(
        imagePath: '/tmp/test.png',
        amount: 100.0,
        date: DateTime(2026, 3, 15),
        extractedText: 'Test',
        createdAt: DateTime.now(),
        category: 'food',
        categorySource: 'ai',
      );
      final map = slip.toMap();
      expect(map['categorySource'], 'ai');
    });

    test('PaymentSlip.fromMap handles null categorySource (pre-v7 rows)', () {
      final map = {
        'id': 1,
        'imagePath': '/tmp/test.png',
        'amount': 100.0,
        'date': DateTime(2026, 3, 15).toIso8601String(),
        'extractedText': 'Test',
        'createdAt': DateTime.now().toIso8601String(),
        'category': 'food',
        'categorySource': null,
        'llmProcessingStatus': 'completed',
        'ragIndexed': 0,
        'retryCount': 0,
        'isRecurring': 0,
      };
      final slip = PaymentSlip.fromMap(map);
      expect(slip.category, 'food');
      expect(slip.categorySource, isNull);
    });

    test('PaymentSlip.copyWith preserves categorySource', () {
      final original = PaymentSlip(
        imagePath: '/tmp/test.png',
        amount: 100.0,
        date: DateTime(2026, 3, 15),
        extractedText: 'Test',
        createdAt: DateTime.now(),
        categorySource: 'rule',
      );
      final copy = original.copyWith(amount: 200.0);
      expect(copy.categorySource, 'rule');
    });

    // ── OCR field regression ─────────────────────────────────────────────

    test('PaymentSlip supports all OCR fields alongside categorySource', () {
      final slip = PaymentSlip(
        imagePath: '/tmp/test.png',
        amount: 100.0,
        date: DateTime(2026, 3, 15),
        extractedText: 'Bank transaction',
        createdAt: DateTime.now(),
        senderName: 'Bank A',
        referenceId: 'REF123',
        senderAccount: '1234567890',
        receiverAccount: '9876543210',
        transactionTime: '15:30',
        category: 'transfer',
        categorySource: 'ai',
      );
      expect(slip.senderName, 'Bank A');
      expect(slip.referenceId, 'REF123');
      expect(slip.senderAccount, '1234567890');
      expect(slip.receiverAccount, '9876543210');
      expect(slip.transactionTime, '15:30');
      expect(slip.categorySource, 'ai');
    });

    // ── CategoryService does not affect built-in lookup ──────────────────

    test('built-in categories still valid when no custom categories exist', () async {
      // No custom categories in the DB
      final valid = await svc.getValidCategoryNames();
      expect(valid, containsAll(['food', 'transport', 'other']));
      expect(valid.length, 14); // only built-ins
    });

    test('adding custom category does not remove built-ins', () async {
      await svc.create('MySuperCat', 'utensils', 'orange');
      final valid = await svc.getValidCategoryNames();
      expect(valid, containsAll(['food', 'transport', 'other']));
      expect(valid, contains('MySuperCat'));
      expect(valid.length, 15);
    });

    test('deleting custom category does not remove built-ins', () async {
      final cat = await svc.create('TempCat', 'utensils', 'orange');
      await svc.delete(cat.id!);
      final valid = await svc.getValidCategoryNames();
      expect(valid, containsAll(['food', 'transport', 'other']));
      expect(valid.length, 14);
    });
  });
}
