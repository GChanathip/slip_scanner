import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanning_state.freezed.dart';

@freezed
abstract class ScanningState with _$ScanningState {
  const ScanningState._(); // Private constructor for custom methods

  const factory ScanningState({
    @Default(false) bool isScanning,
    @Default(0) int totalPhotos,
    @Default(0) int processedPhotos,
    @Default(0) int slipsFound,
    @Default(false) bool isComplete,
    String? error,
  }) = _ScanningState;

  double get progress => totalPhotos > 0 ? processedPhotos / totalPhotos : 0.0;
}
