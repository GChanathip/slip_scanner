import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/analysis_provider.dart';
import '../providers/analysis_state.dart';
import '../providers/cactus_provider.dart';
import '../providers/extraction_provider.dart';
import '../router/app_router.dart';

@RoutePage()
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;

    // Load analysis
    Future.microtask(() {
      ref.read(analysisProvider.notifier).loadAnalysis(startDate: _startDate, endDate: _endDate);
      _ensureModelLoaded();
    });
  }

  Future<void> _ensureModelLoaded() async {
    final cactusState = ref.read(cactusProvider);
    if (!cactusState.isModelLoaded && !cactusState.isLoading) {
      await ref.read(cactusProvider.notifier).downloadAndInitialize(cactusState.selectedModel);
      if (ref.read(cactusProvider).isModelLoaded) {
        ref.read(extractionQueueProvider.notifier).startBackgroundProcessing();
      }
    }
  }

  void _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      ref.read(analysisProvider.notifier).loadAnalysis(startDate: _startDate, endDate: _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final analysisState = ref.watch(analysisProvider);
    final extractionState = ref.watch(extractionQueueProvider);
    final cactusState = ref.watch(cactusProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Expense Analysis'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
        suffixes: [
          FHeaderAction(icon: const Icon(FIcons.settings), onPress: () => context.router.push(const SettingsRoute())),
        ],
      ),
      child: Stack(
        children: [
          analysisState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Date Range Picker
                    GestureDetector(
                      onTap: _selectDateRange,
                      child: FCard.raw(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(FIcons.calendar, color: theme.colors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date Range', style: theme.typography.sm),
                                    Text(
                                      _formatDateRange(),
                                      style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Processing Status (if pending)
                    if (extractionState.hasPending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FAlert(
                          icon: Icon(FIcons.loaderCircle, color: theme.colors.primary),
                          title: const Text('Processing'),
                          subtitle: Text('${extractionState.pendingCount} slips pending AI analysis'),
                        ),
                      ),

                    // Summary Stats
                    if (analysisState.hasData) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Total',
                              '${analysisState.totalSpending.toStringAsFixed(0)} ฿',
                              FIcons.wallet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Transactions',
                              analysisState.transactionCount.toString(),
                              FIcons.receipt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Average',
                              '${analysisState.averageTransaction.toStringAsFixed(0)} ฿',
                              FIcons.calculator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Top Category',
                              _formatCategory(analysisState.topCategory ?? 'N/A'),
                              FIcons.tag,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Category Breakdown
                      if (analysisState.categoryBreakdown.isNotEmpty) ...[
                        Text('Spending by Category', style: theme.typography.xl),
                        const SizedBox(height: 12),
                        ...analysisState.categoryBreakdown.entries
                            .toList()
                            .sorted((a, b) => b.value.compareTo(a.value))
                            .map(
                              (entry) => _buildCategoryRow(theme, entry.key, entry.value, analysisState.totalSpending),
                            ),
                      ],

                      const SizedBox(height: 24),

                      // Insights
                      if (analysisState.insights.isNotEmpty) ...[
                        Text('Insights', style: theme.typography.xl),
                        const SizedBox(height: 12),
                        ...analysisState.insights.map((insight) => _buildInsightCard(theme, insight)),
                      ],
                    ] else ...[
                      // No data state
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48),
                            Icon(FIcons.chartPie, size: 64, color: theme.colors.mutedForeground),
                            const SizedBox(height: 16),
                            Text('No expense data', style: theme.typography.xl),
                            const SizedBox(height: 8),
                            Text(
                              'Scan some payment slips to see your analysis',
                              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
          // Ask AI Floating Action Button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: cactusState.isModelLoaded
                  ? () => context.router.push(ChatRoute(startDate: _startDate, endDate: _endDate))
                  : null,
              icon: const Icon(FIcons.messageCircle),
              label: const Text('Ask AI'),
              backgroundColor: cactusState.isModelLoaded ? theme.colors.primary : theme.colors.muted,
              foregroundColor: cactusState.isModelLoaded
                  ? theme.colors.primaryForeground
                  : theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(FThemeData theme, String label, String value, IconData icon) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colors.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label, style: theme.typography.sm, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.typography.xl2),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(FThemeData theme, String category, double amount, double total) {
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _getCategoryIcon(category, theme),
                  const SizedBox(width: 8),
                  Text(_formatCategory(category), style: theme.typography.base),
                ],
              ),
              Text(
                '${amount.toStringAsFixed(0)} ฿',
                style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: percentage, backgroundColor: theme.colors.muted),
        ],
      ),
    );
  }

  Widget _buildInsightCard(FThemeData theme, InsightData insight) {
    Color getColor() {
      switch (insight.type) {
        case 'anomaly':
          return Colors.orange;
        case 'suggestion':
          return Colors.blue;
        default:
          return theme.colors.primary;
      }
    }

    IconData getIcon() {
      switch (insight.icon) {
        case 'trending_up':
          return FIcons.trendingUp;
        case 'trending_down':
          return FIcons.trendingDown;
        case 'alert':
          return FIcons.triangleAlert;
        case 'chart':
          return FIcons.chartBar;
        case 'lightbulb':
          return FIcons.lightbulb;
        case 'info':
          return FIcons.info;
        default:
          return FIcons.sparkles;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(getIcon(), color: getColor(), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title, style: theme.typography.base.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(insight.description, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category, FThemeData theme) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'food':
        icon = FIcons.utensils;
        break;
      case 'transport':
        icon = FIcons.car;
        break;
      case 'utilities':
        icon = FIcons.zap;
        break;
      case 'shopping':
        icon = FIcons.shoppingBag;
        break;
      case 'transfer':
        icon = FIcons.arrowRightLeft;
        break;
      case 'entertainment':
        icon = FIcons.gamepad2;
        break;
      case 'health':
        icon = FIcons.heart;
        break;
      case 'education':
        icon = FIcons.graduationCap;
        break;
      default:
        icon = FIcons.circle;
    }
    return Icon(icon, size: 18, color: theme.colors.primary);
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return 'Other';
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatDateRange() {
    if (_startDate == null && _endDate == null) return 'All time';
    final startStr = _startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Beginning';
    final endStr = _endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Now';
    return '$startStr - $endStr';
  }
}

extension ListExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final list = [...this];
    list.sort(compare);
    return list;
  }
}
