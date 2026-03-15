// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Budget)
final budgetProvider = BudgetProvider._();

final class BudgetProvider extends $NotifierProvider<Budget, BudgetState> {
  BudgetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetHash();

  @$internal
  @override
  Budget create() => Budget();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetState>(value),
    );
  }
}

String _$budgetHash() => r'dda78e2d2babda7c1112b24a5774577f6c8efe6c';

abstract class _$Budget extends $Notifier<BudgetState> {
  BudgetState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BudgetState, BudgetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BudgetState, BudgetState>,
              BudgetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
