import 'package:sqflite/sqflite.dart';
import '../models/custom_category.dart';
import '../models/category_rule.dart';
import '../models/category_registry.dart';

const _kMaxCustomCategories = 20;

/// Service for managing user-defined categories and learning rules.
///
/// Designed for DI: production code calls [CategoryService.create()] or
/// uses [CategoryService(db)] directly with a pre-opened [Database].
class CategoryService {
  final Database _db;

  CategoryService(this._db);

  // ─── Custom Categories ───────────────────────────────────────────────────

  /// Return all user-defined categories ordered by name.
  Future<List<CustomCategory>> getAll() async {
    final rows = await _db.query('custom_categories', orderBy: 'name ASC');
    return rows.map(CustomCategory.fromMap).toList();
  }

  /// Create a new custom category.
  ///
  /// Throws [StateError] if the 20-category limit is reached.
  /// Throws [ArgumentError] on case-insensitive duplicate name.
  Future<CustomCategory> create(String name, String icon, String color) async {
    final trimmed = name.trim();

    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM custom_categories'),
    )!;
    if (count >= _kMaxCustomCategories) {
      throw StateError('Custom category limit ($_kMaxCustomCategories) reached');
    }

    // Case-insensitive dupe check (COLLATE NOCASE handles this at DB level,
    // but we surface a clear error before hitting the UNIQUE constraint).
    final existing = await _db.query(
      'custom_categories',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw ArgumentError('Category "$trimmed" already exists');
    }

    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('custom_categories', {
      'name': trimmed,
      'icon': icon,
      'color': color,
      'createdAt': now,
    });

    return CustomCategory(
      id: id,
      name: trimmed,
      icon: icon,
      color: color,
      createdAt: now,
    );
  }

  /// Update an existing custom category.
  ///
  /// If [name] changes, cascades the new name to [payment_slips.category]
  /// and [category_rules.category] inside a single transaction.
  Future<void> update(int id, {String? name, String? icon, String? color}) async {
    if (name == null && icon == null && color == null) return;

    final rows = await _db.query(
      'custom_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Category $id not found');
    final oldName = rows.first['name'] as String;
    final newName = name?.trim() ?? oldName;

    await _db.transaction((txn) async {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = newName;
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      await txn.update('custom_categories', updates, where: 'id = ?', whereArgs: [id]);

      if (name != null && newName != oldName) {
        await txn.update(
          'payment_slips',
          {'category': newName},
          where: 'category = ?',
          whereArgs: [oldName],
        );
        await txn.update(
          'category_rules',
          {'category': newName},
          where: 'category = ?',
          whereArgs: [oldName],
        );
      }
    });
  }

  /// Delete a custom category.
  ///
  /// Cascades all [payment_slips] with this category to 'other',
  /// and deletes all [category_rules] pointing to it — atomically.
  Future<void> delete(int id) async {
    final rows = await _db.query(
      'custom_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final name = rows.first['name'] as String;

    await _db.transaction((txn) async {
      await txn.update(
        'payment_slips',
        {'category': 'other'},
        where: 'category = ?',
        whereArgs: [name],
      );
      await txn.delete('category_rules', where: 'category = ?', whereArgs: [name]);
      await txn.delete('custom_categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Merge [sourceId] into [targetCategory] (a built-in slug or custom name).
  ///
  /// Cascades payment_slips + category_rules to [targetCategory],
  /// then deletes the source custom category — atomically.
  Future<void> merge(int sourceId, String targetCategory) async {
    final rows = await _db.query(
      'custom_categories',
      where: 'id = ?',
      whereArgs: [sourceId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Source category $sourceId not found');
    final sourceName = rows.first['name'] as String;

    await _db.transaction((txn) async {
      await txn.update(
        'payment_slips',
        {'category': targetCategory},
        where: 'category = ?',
        whereArgs: [sourceName],
      );
      await txn.update(
        'category_rules',
        {'category': targetCategory},
        where: 'category = ?',
        whereArgs: [sourceName],
      );
      await txn.delete('custom_categories', where: 'id = ?', whereArgs: [sourceId]);
    });
  }

  // ─── Category Rules ──────────────────────────────────────────────────────

  /// Find a rule for a (normalized) recipient name.
  ///
  /// Returns null when no rule matches.
  Future<CategoryRule?> findRule(String recipientName) async {
    final pattern = normalizeRecipient(recipientName);
    final rows = await _db.query(
      'category_rules',
      where: 'recipientPattern = ?',
      whereArgs: [pattern],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CategoryRule.fromMap(rows.first);
  }

  /// Insert or update a category rule for [recipientName].
  Future<void> upsertRule(String recipientName, String category) async {
    final pattern = normalizeRecipient(recipientName);
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      'category_rules',
      {
        'recipientPattern': pattern,
        'category': category,
        'source': 'user',
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete the rule for [recipientPattern] (exact, already normalized).
  Future<void> deleteRule(String recipientPattern) async {
    await _db.delete(
      'category_rules',
      where: 'recipientPattern = ?',
      whereArgs: [recipientPattern],
    );
  }

  /// Return all category rules ordered by pattern.
  Future<List<CategoryRule>> getAllRules() async {
    final rows = await _db.query('category_rules', orderBy: 'recipientPattern ASC');
    return rows.map(CategoryRule.fromMap).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Normalize a recipient name for rule matching:
  /// lowercase, trimmed, collapsed whitespace.
  String normalizeRecipient(String name) =>
      name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Return the set of valid category names:
  /// all built-in slugs plus every custom category name.
  Future<Set<String>> getValidCategoryNames() async {
    final custom = await getAll();
    return {...kBuiltInCategorySlugs, ...custom.map((c) => c.name)};
  }
}
