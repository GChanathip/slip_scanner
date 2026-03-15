// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All built-in categories with their slip counts.

@ProviderFor(builtinCategoriesWithCounts)
final builtinCategoriesWithCountsProvider =
    BuiltinCategoriesWithCountsProvider._();

/// All built-in categories with their slip counts.

final class BuiltinCategoriesWithCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuiltInCategoryWithCount>>,
          List<BuiltInCategoryWithCount>,
          FutureOr<List<BuiltInCategoryWithCount>>
        >
    with
        $FutureModifier<List<BuiltInCategoryWithCount>>,
        $FutureProvider<List<BuiltInCategoryWithCount>> {
  /// All built-in categories with their slip counts.
  BuiltinCategoriesWithCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'builtinCategoriesWithCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$builtinCategoriesWithCountsHash();

  @$internal
  @override
  $FutureProviderElement<List<BuiltInCategoryWithCount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BuiltInCategoryWithCount>> create(Ref ref) {
    return builtinCategoriesWithCounts(ref);
  }
}

String _$builtinCategoriesWithCountsHash() =>
    r'f77bded70d0a4963b2353fb9a2b968426cb5e1d0';

/// All custom categories with their slip counts.

@ProviderFor(customCategoriesWithCounts)
final customCategoriesWithCountsProvider =
    CustomCategoriesWithCountsProvider._();

/// All custom categories with their slip counts.

final class CustomCategoriesWithCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomCategoryWithCount>>,
          List<CustomCategoryWithCount>,
          FutureOr<List<CustomCategoryWithCount>>
        >
    with
        $FutureModifier<List<CustomCategoryWithCount>>,
        $FutureProvider<List<CustomCategoryWithCount>> {
  /// All custom categories with their slip counts.
  CustomCategoriesWithCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customCategoriesWithCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customCategoriesWithCountsHash();

  @$internal
  @override
  $FutureProviderElement<List<CustomCategoryWithCount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomCategoryWithCount>> create(Ref ref) {
    return customCategoriesWithCounts(ref);
  }
}

String _$customCategoriesWithCountsHash() =>
    r'225ca272131b0fdd6e6fdce476c745385506c841';

/// Combined list of all valid category names (built-in slugs + custom names).

@ProviderFor(allCategoryNames)
final allCategoryNamesProvider = AllCategoryNamesProvider._();

/// Combined list of all valid category names (built-in slugs + custom names).

final class AllCategoryNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Combined list of all valid category names (built-in slugs + custom names).
  AllCategoryNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allCategoryNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allCategoryNamesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return allCategoryNames(ref);
  }
}

String _$allCategoryNamesHash() => r'd4b70a528a2a34b0de623391bb3f1c838fb66348';

/// Notifier providing category mutation methods.
///
/// Each mutation invalidates the dependent providers so watchers rebuild.

@ProviderFor(CategoryMutations)
final categoryMutationsProvider = CategoryMutationsProvider._();

/// Notifier providing category mutation methods.
///
/// Each mutation invalidates the dependent providers so watchers rebuild.
final class CategoryMutationsProvider
    extends $AsyncNotifierProvider<CategoryMutations, void> {
  /// Notifier providing category mutation methods.
  ///
  /// Each mutation invalidates the dependent providers so watchers rebuild.
  CategoryMutationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryMutationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryMutationsHash();

  @$internal
  @override
  CategoryMutations create() => CategoryMutations();
}

String _$categoryMutationsHash() => r'1ff7b01dd81edf5da4155c176c8a8ca39eef82b1';

/// Notifier providing category mutation methods.
///
/// Each mutation invalidates the dependent providers so watchers rebuild.

abstract class _$CategoryMutations extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
