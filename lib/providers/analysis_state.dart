import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_state.freezed.dart';

@freezed
abstract class InsightData with _$InsightData {
  const factory InsightData({
    required String title,
    required String description,
    required String type, // 'trend', 'anomaly', 'suggestion'
    double? value,
    String? icon, // icon name for UI
  }) = _InsightData;
}

@freezed
abstract class AnalysisState with _$AnalysisState {
  const AnalysisState._();

  const factory AnalysisState({
    @Default([]) List<InsightData> insights,
    @Default({}) Map<String, double> categoryBreakdown,
    @Default({}) Map<String, double> monthlyTrend,
    @Default(0.0) double totalSpending,
    @Default(0) int transactionCount,
    @Default(0.0) double averageTransaction,
    @Default(false) bool isLoading,
    DateTime? startDate,
    DateTime? endDate,
    String? error,
  }) = _AnalysisState;

  /// Whether analysis has data
  bool get hasData => transactionCount > 0;

  /// Top spending category
  String? get topCategory {
    if (categoryBreakdown.isEmpty) return null;
    return categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
