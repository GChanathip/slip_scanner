import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
    final theme = ShadTheme.of(context);
    final analysisState = ref.watch(analysisProvider);
    final cactusState = ref.watch(cactusProvider);
    final extractionState = ref.watch(extractionQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        leading: ShadIconButton.ghost(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.foreground),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          ShadIconButton.ghost(
            icon: Icon(LucideIcons.settings, color: theme.colorScheme.foreground),
            onPressed: () => context.router.push(const SettingsRoute()),
          ),
        ],
      ),
      body: analysisState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(analysisProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Range Picker
                  ShadCard(
                    child: InkWell(
                      onTap: _selectDateRange,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date Range', style: theme.textTheme.small),
                                  Text(
                                    _formatDateRange(),
                                    style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, color: theme.colorScheme.mutedForeground),
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
                      child: ShadAlert(
                        icon: Icon(LucideIcons.loaderCircle, color: theme.colorScheme.primary),
                        title: const Text('Processing'),
                        description: Text('${extractionState.pendingCount} slips pending AI analysis'),
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
                            LucideIcons.wallet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Transactions',
                            analysisState.transactionCount.toString(),
                            LucideIcons.receipt,
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
                            LucideIcons.calculator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            'Top Category',
                            _formatCategory(analysisState.topCategory ?? 'N/A'),
                            LucideIcons.tag,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown
                    if (analysisState.categoryBreakdown.isNotEmpty) ...[
                      Text('Spending by Category', style: theme.textTheme.h4),
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
                      Text('Insights', style: theme.textTheme.h4),
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
                          Icon(LucideIcons.chartPie, size: 64, color: theme.colorScheme.mutedForeground),
                          const SizedBox(height: 16),
                          Text('No expense data', style: theme.textTheme.h4),
                          const SizedBox(height: 8),
                          Text(
                            'Scan some payment slips to see your analysis',
                            style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: cactusState.isModelLoaded
            ? () => context.router.push(ChatRoute(startDate: _startDate, endDate: _endDate))
            : null,
        icon: const Icon(LucideIcons.messageCircle),
        label: const Text('Ask AI'),
        backgroundColor: cactusState.isModelLoaded ? null : Colors.grey,
      ),
    );
  }

  Widget _buildStatCard(ShadThemeData theme, String label, String value, IconData icon) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label, style: theme.textTheme.small, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.h3),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(ShadThemeData theme, String category, double amount, double total) {
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
                  Text(_formatCategory(category), style: theme.textTheme.p),
                ],
              ),
              Text('${amount.toStringAsFixed(0)} ฿', style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: percentage, backgroundColor: theme.colorScheme.muted),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ShadThemeData theme, InsightData insight) {
    Color getColor() {
      switch (insight.type) {
        case 'anomaly':
          return Colors.orange;
        case 'suggestion':
          return Colors.blue;
        default:
          return theme.colorScheme.primary;
      }
    }

    IconData getIcon() {
      switch (insight.icon) {
        case 'trending_up':
          return LucideIcons.trendingUp;
        case 'trending_down':
          return LucideIcons.trendingDown;
        case 'alert':
          return LucideIcons.triangleAlert;
        case 'chart':
          return LucideIcons.chartBar;
        case 'lightbulb':
          return LucideIcons.lightbulb;
        case 'info':
          return LucideIcons.info;
        default:
          return LucideIcons.sparkles;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
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
                    Text(insight.title, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category, ShadThemeData theme) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'food':
        icon = LucideIcons.utensils;
        break;
      case 'transport':
        icon = LucideIcons.car;
        break;
      case 'utilities':
        icon = LucideIcons.zap;
        break;
      case 'shopping':
        icon = LucideIcons.shoppingBag;
        break;
      case 'transfer':
        icon = LucideIcons.arrowRightLeft;
        break;
      case 'entertainment':
        icon = LucideIcons.gamepad2;
        break;
      case 'health':
        icon = LucideIcons.heart;
        break;
      case 'education':
        icon = LucideIcons.graduationCap;
        break;
      default:
        icon = LucideIcons.circle;
    }
    return Icon(icon, size: 18, color: theme.colorScheme.primary);
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
