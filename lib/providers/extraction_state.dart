import 'package:freezed_annotation/freezed_annotation.dart';

part 'extraction_state.freezed.dart';

@freezed
abstract class ExtractionQueueState with _$ExtractionQueueState {
  const ExtractionQueueState._();

  const factory ExtractionQueueState({
    @Default(0) int pendingCount,
    @Default(0) int processedCount,
    @Default(0) int failedCount,
    @Default(false) bool isProcessing,
    int? currentSlipId,
  }) = _ExtractionQueueState;

  /// Whether there are pending items to process
  bool get hasPending => pendingCount > 0;
}
