// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extraction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExtractionQueue)
final extractionQueueProvider = ExtractionQueueProvider._();

final class ExtractionQueueProvider
    extends $NotifierProvider<ExtractionQueue, ExtractionQueueState> {
  ExtractionQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'extractionQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$extractionQueueHash();

  @$internal
  @override
  ExtractionQueue create() => ExtractionQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExtractionQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExtractionQueueState>(value),
    );
  }
}

String _$extractionQueueHash() => r'7260184ce0cfc5103b472377845547376a2259a9';

abstract class _$ExtractionQueue extends $Notifier<ExtractionQueueState> {
  ExtractionQueueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExtractionQueueState, ExtractionQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExtractionQueueState, ExtractionQueueState>,
              ExtractionQueueState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
