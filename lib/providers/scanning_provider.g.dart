// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanning_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Scanning)
final scanningProvider = ScanningProvider._();

final class ScanningProvider
    extends $NotifierProvider<Scanning, ScanningState> {
  ScanningProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanningProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanningHash();

  @$internal
  @override
  Scanning create() => Scanning();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanningState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanningState>(value),
    );
  }
}

String _$scanningHash() => r'c9ad63ce3b0786b6d039dc9132fd56769dca37c3';

abstract class _$Scanning extends $Notifier<ScanningState> {
  ScanningState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScanningState, ScanningState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanningState, ScanningState>,
              ScanningState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
