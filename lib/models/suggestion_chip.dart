import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggestion_chip.freezed.dart';

@freezed
abstract class SuggestionChip with _$SuggestionChip {
  const factory SuggestionChip({
    required String label,
    required String query,
    String? icon,
  }) = _SuggestionChip;
}
