import 'package:freezed_annotation/freezed_annotation.dart';

part 'cactus_state.freezed.dart';

@freezed
abstract class CactusState with _$CactusState {
  const CactusState._();

  const factory CactusState({
    @Default(false) bool isDownloading,
    @Default(false) bool isInitializing,
    @Default(false) bool isModelLoaded,
    @Default(0.0) double downloadProgress,
    @Default('') String downloadStatus,
    @Default('qwen3-0.6') String selectedModel,
    String? error,
  }) = _CactusState;

  /// Overall loading state (downloading or initializing)
  bool get isLoading => isDownloading || isInitializing;
}
