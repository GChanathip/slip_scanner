// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cactus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Cactus)
final cactusProvider = CactusProvider._();

final class CactusProvider extends $NotifierProvider<Cactus, CactusState> {
  CactusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cactusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cactusHash();

  @$internal
  @override
  Cactus create() => Cactus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CactusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CactusState>(value),
    );
  }
}

String _$cactusHash() => r'5efac546d4c501c3f3c328f16529238c1ca6ed70';

abstract class _$Cactus extends $Notifier<CactusState> {
  CactusState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CactusState, CactusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CactusState, CactusState>,
              CactusState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
