// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Analysis)
final analysisProvider = AnalysisProvider._();

final class AnalysisProvider
    extends $NotifierProvider<Analysis, AnalysisState> {
  AnalysisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisHash();

  @$internal
  @override
  Analysis create() => Analysis();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisState>(value),
    );
  }
}

String _$analysisHash() => r'f6c499d3725e9fe42f464aeb89ff4729b1484b7c';

abstract class _$Analysis extends $Notifier<AnalysisState> {
  AnalysisState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AnalysisState, AnalysisState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalysisState, AnalysisState>,
              AnalysisState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
