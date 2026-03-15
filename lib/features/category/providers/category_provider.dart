import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:avers/core/models/category_registry.dart';
import 'package:avers/features/category/models/custom_category.dart';
import 'package:avers/features/category/services/category_service.dart';
import 'package:avers/core/database/database_service.dart';

part 'category_provider.g.dart';

/// Record holding a built-in category and its slip count.
typedef BuiltInCategoryWithCount = ({BuiltInCategory cat, int count});

/// Record holding a custom category and its slip count.
typedef CustomCategoryWithCount = ({CustomCategory cat, int count});

/// All built-in categories with their slip counts.
@riverpod
Future<List<BuiltInCategoryWithCount>> builtinCategoriesWithCounts(
  Ref ref,
) async {
  final db = await DatabaseService.database;

  // Single query for all category counts.
  final rows = await db.rawQuery(
    'SELECT category, COUNT(*) AS cnt FROM payment_slips '
    'WHERE category IS NOT NULL GROUP BY category',
  );
  final countMap = <String, int>{
    for (final r in rows) r['category'] as String: r['cnt'] as int,
  };

  return [
    for (final cat in kBuiltInCategories)
      (cat: cat, count: countMap[cat.slug] ?? 0),
  ];
}

/// All custom categories with their slip counts.
@riverpod
Future<List<CustomCategoryWithCount>> customCategoriesWithCounts(
  Ref ref,
) async {
  final db = await DatabaseService.database;
  final svc = CategoryService(db);
  final categories = await svc.getAll();

  if (categories.isEmpty) return [];

  // Single query for custom category counts.
  final placeholders = List.filled(categories.length, '?').join(',');
  final names = categories.map((c) => c.name).toList();
  final rows = await db.rawQuery(
    'SELECT category, COUNT(*) AS cnt FROM payment_slips '
    'WHERE category IN ($placeholders) GROUP BY category',
    names,
  );
  final countMap = <String, int>{
    for (final r in rows) r['category'] as String: r['cnt'] as int,
  };

  return [
    for (final cat in categories) (cat: cat, count: countMap[cat.name] ?? 0),
  ];
}

/// Combined list of all valid category names (built-in slugs + custom names).
@riverpod
Future<List<String>> allCategoryNames(Ref ref) async {
  final db = await DatabaseService.database;
  final svc = CategoryService(db);
  final custom = await svc.getAll();
  return [
    ...kBuiltInCategorySlugs,
    ...custom.map((c) => c.name),
  ];
}

/// Notifier providing category mutation methods.
///
/// Each mutation invalidates the dependent providers so watchers rebuild.
@riverpod
class CategoryMutations extends _$CategoryMutations {
  @override
  FutureOr<void> build() {}

  /// Create or update a custom category.
  Future<void> saveCategory({
    int? id,
    required String name,
    required String icon,
    required String color,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = await DatabaseService.database;
      final svc = CategoryService(db);
      if (id != null) {
        await svc.update(id, name: name, icon: icon, color: color);
      } else {
        await svc.create(name, icon, color);
      }
      _invalidateAll();
    });
  }

  /// Delete a custom category (slips cascade to 'other').
  Future<void> deleteCategory(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = await DatabaseService.database;
      final svc = CategoryService(db);
      await svc.delete(id);
      _invalidateAll();
    });
  }

  /// Merge a custom category into a target (built-in slug or custom name).
  Future<void> mergeCategory(int sourceId, String targetCategory) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = await DatabaseService.database;
      final svc = CategoryService(db);
      await svc.merge(sourceId, targetCategory);
      _invalidateAll();
    });
  }

  void _invalidateAll() {
    ref.invalidate(builtinCategoriesWithCountsProvider);
    ref.invalidate(customCategoriesWithCountsProvider);
    ref.invalidate(allCategoryNamesProvider);
  }
}
