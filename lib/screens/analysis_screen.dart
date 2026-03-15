import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:slip_scanner/providers/budget_state.dart';
import '../providers/analysis_provider.dart';
import '../providers/analysis_state.dart';
import '../providers/budget_provider.dart';
import '../providers/cactus_provider.dart';
import '../providers/extraction_provider.dart';
import '../router/app_router.dart';
import '../utils/ensure_model.dart';
import '../utils/formatters.dart';

const _categoryIcons = <String, IconData>{
  'food': FIcons.utensils,
  'transport': FIcons.car,
  'utilities': FIcons.zap,
  'shopping': FIcons.shoppingBag,
  'transfer': FIcons.arrowRightLeft,
  'entertainment': FIcons.gamepad2,
  'health': FIcons.heart,
  'education': FIcons.graduationCap,
};

const _insightIcons = <String, IconData>{
  'trending_up': FIcons.trendingUp,
  'trending_down': FIcons.trendingDown,
  'alert': FIcons.triangleAlert,
  'chart': FIcons.chartBar,
  'lightbulb': FIcons.lightbulb,
  'info': FIcons.info,
};

const _insightColors = <String, Color>{
  'anomaly': Colors.orange,
  'suggestion': Colors.blue,
};

const _viewLabels = <AnalyticsView, String>{
  AnalyticsView.summary: 'Summary',
  AnalyticsView.daily: 'Daily',
  AnalyticsView.weekly: 'Weekly',
  AnalyticsView.recipients: 'Recipients',
  AnalyticsView.categoryTrend: 'Trends',
};

const _viewIcons = <AnalyticsView, IconData>{
  AnalyticsView.summary: FIcons.chartPie,
  AnalyticsView.daily: FIcons.chartBar,
  AnalyticsView.weekly: FIcons.calendar,
  AnalyticsView.recipients: FIcons.users,
  AnalyticsView.categoryTrend: FIcons.trendingUp,
};

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
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;

    Future.microtask(() {
      ref.read(analysisProvider.notifier).loadAnalysis(startDate: _startDate, endDate: _endDate);
      _ensureModelLoaded();
    });
  }

  Future<void> _ensureModelLoaded() async {
    await ensureModelLoaded(context, ref);
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

  void _applyPreset(String label, DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    ref.read(analysisProvider.notifier).loadAnalysis(startDate: start, endDate: end);
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
                    _buildDateRangePicker(theme),
                    const SizedBox(height: 12),

                    // Quick Filter Presets
                    _buildFilterPresets(theme),
                    const SizedBox(height: 16),

                    // Processing Status
                    if (extractionState.hasPending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FAlert(
                          icon: Icon(FIcons.loaderCircle, color: theme.colors.primary),
                          title: const Text('Processing'),
                          subtitle: Text('${extractionState.pendingCount} slips pending AI analysis'),
                        ),
                      ),

                    if (analysisState.hasData) ...[
                      // Summary Stats (always visible)
                      _buildSummaryStats(theme, analysisState),
                      const SizedBox(height: 20),

                      // View Tabs
                      _buildViewTabs(theme, analysisState.activeView),
                      const SizedBox(height: 16),

                      // Active View Content
                      _buildActiveView(theme, analysisState),
                    ] else ...[
                      _buildEmptyState(theme),
                    ],
                  ],
                ),
          // Ask AI Button
          Positioned(
            right: 16,
            bottom: 16,
            child: FButton(
              onPress: cactusState.isModelLoaded
                  ? () => context.router.push(ChatRoute(startDate: _startDate, endDate: _endDate))
                  : null,
              prefix: Icon(FIcons.messageCircle, size: 18),
              child: const Text('Ask AI'),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Date & Filter Widgets ============

  Widget _buildDateRangePicker(FThemeData theme) {
    return Semantics(
      button: true,
      label: 'Select date range',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDateRange,
          borderRadius: theme.style.borderRadius,
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
                          formatDateRange(_startDate, _endDate),
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
      ),
    );
  }

  Widget _buildFilterPresets(FThemeData theme) {
    final now = DateTime.now();
    final presets = <(String, DateTime, DateTime)>[
      ('Today', DateTime(now.year, now.month, now.day), now),
      ('This Week', now.subtract(Duration(days: now.weekday - 1)), now),
      ('This Month', DateTime(now.year, now.month, 1), now),
      ('Last 7 Days', now.subtract(const Duration(days: 7)), now),
      ('Last 30 Days', now.subtract(const Duration(days: 30)), now),
      ('Last 90 Days', now.subtract(const Duration(days: 90)), now),
      ('This Year', DateTime(now.year, 1, 1), now),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, start, end) = presets[index];
          final isActive = _startDate != null &&
              _startDate!.year == start.year &&
              _startDate!.month == start.month &&
              _startDate!.day == start.day;

          return FButton(
            variant: isActive ? null : FButtonVariant.outline,
            onPress: () => _applyPreset(label, start, end),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          );
        },
      ),
    );
  }

  // ============ View Tab Bar ============

  Widget _buildViewTabs(FThemeData theme, AnalyticsView activeView) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AnalyticsView.values.map((view) {
          final isActive = view == activeView;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FButton(
              variant: isActive ? null : FButtonVariant.outline,
              onPress: () => ref.read(analysisProvider.notifier).setActiveView(view),
              prefix: Icon(_viewIcons[view] ?? FIcons.chartBar, size: 14),
              child: Text(_viewLabels[view] ?? '', style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============ Active View Routing ============

  Widget _buildActiveView(FThemeData theme, AnalysisState state) {
    return switch (state.activeView) {
      AnalyticsView.summary => _buildSummaryView(theme, state),
      AnalyticsView.daily => _buildDailyView(theme, state),
      AnalyticsView.weekly => _buildWeeklyView(theme, state),
      AnalyticsView.recipients => _buildRecipientsView(theme, state),
      AnalyticsView.categoryTrend => _buildCategoryTrendView(theme, state),
    };
  }

  // ============ Summary View ============

  Widget _buildSummaryView(FThemeData theme, AnalysisState state) {
    final budgetState = ref.watch(budgetProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget Progress
        if (budgetState.hasBudget) ...[
          _buildBudgetProgressCard(theme, budgetState),
          const SizedBox(height: 16),
        ] else ...[
          _buildSetBudgetCard(theme),
          const SizedBox(height: 16),
        ],

        // Per-category budget bars
        if (budgetState.categoryBudgets.isNotEmpty) ...[
          _buildCategoryBudgetBars(theme, budgetState),
          const SizedBox(height: 16),
        ],

        // Category Breakdown
        if (state.categoryBreakdown.isNotEmpty) ...[
          Text('Spending by Category', style: theme.typography.xl),
          const SizedBox(height: 12),
          ...(state.categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .map((entry) => _buildCategoryRow(theme, entry.key, entry.value, state.totalSpending)),
        ],
        const SizedBox(height: 24),
        // Insights
        if (state.insights.isNotEmpty) ...[
          Text('Insights', style: theme.typography.xl),
          const SizedBox(height: 12),
          ...state.insights.map((insight) => _buildInsightCard(theme, insight)),
        ],
        const SizedBox(height: 60), // Space for FAB
      ],
    );
  }

  // ============ Daily View ============

  Widget _buildDailyView(FThemeData theme, AnalysisState state) {
    final dailyTotals = state.dailyTotals;
    if (dailyTotals.isEmpty) return _buildNoDataForView(theme, 'No daily data for this range');

    final maxAmount = dailyTotals.values.reduce(math.max);
    final entries = dailyTotals.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Spending', style: theme.typography.xl),
        const SizedBox(height: 4),
        Text(
          '${entries.length} days, avg ${formatCurrencyCompact(state.totalSpending / entries.length)}/day',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) {
          final barWidth = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final dateParts = entry.key.split('-');
          final dayLabel = '${dateParts[2]}/${dateParts[1]}';
          return _buildBarRow(theme, dayLabel, entry.value, barWidth);
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  // ============ Weekly View ============

  Widget _buildWeeklyView(FThemeData theme, AnalysisState state) {
    final weeklyTotals = state.weeklyTotals;
    if (weeklyTotals.isEmpty) return _buildNoDataForView(theme, 'No weekly data for this range');

    final maxAmount = weeklyTotals.values.reduce(math.max);
    final entries = weeklyTotals.entries.toList();

    // Calculate week-over-week changes
    final changes = <String, double?>{};
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        final prev = entries[i - 1].value;
        changes[entries[i].key] = prev > 0 ? ((entries[i].value - prev) / prev * 100) : null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Breakdown', style: theme.typography.xl),
        const SizedBox(height: 4),
        Text(
          '${entries.length} weeks',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) {
          final barWidth = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final change = changes[entry.key];
          return _buildWeekRow(theme, entry.key, entry.value, barWidth, change);
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  // ============ Recipients View ============

  Widget _buildRecipientsView(FThemeData theme, AnalysisState state) {
    final recipients = state.topRecipients;
    if (recipients.isEmpty) return _buildNoDataForView(theme, 'No recipient data yet (pending AI analysis)');

    final maxAmount = recipients.values.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Recipients', style: theme.typography.xl),
        const SizedBox(height: 4),
        Text(
          'Where your money goes',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        ...recipients.entries.toList().asMap().entries.map((indexed) {
          final entry = indexed.value;
          final rank = indexed.key + 1;
          final barWidth = maxAmount > 0 ? entry.value / maxAmount : 0.0;
          final percentage = state.totalSpending > 0 ? (entry.value / state.totalSpending * 100) : 0.0;
          return _buildRecipientRow(theme, rank, entry.key, entry.value, barWidth, percentage);
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  // ============ Category Trend View ============

  Widget _buildCategoryTrendView(FThemeData theme, AnalysisState state) {
    final trend = state.categoryTrend;
    if (trend.isEmpty) return _buildNoDataForView(theme, 'No trend data for this range');

    // Collect all categories
    final allCategories = <String>{};
    for (final monthData in trend.values) {
      allCategories.addAll(monthData.keys);
    }

    // Sort months
    final months = trend.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Trends', style: theme.typography.xl),
        const SizedBox(height: 4),
        Text(
          'Spending by category over ${months.length} months',
          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        // Show each category's monthly progression
        ...allCategories.map((category) {
          final categoryMonthly = <String, double>{};
          for (final month in months) {
            categoryMonthly[month] = trend[month]?[category] ?? 0;
          }
          return _buildCategoryTrendCard(theme, category, categoryMonthly);
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildCategoryTrendCard(FThemeData theme, String category, Map<String, double> monthlyData) {
    final total = monthlyData.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    final maxAmount = monthlyData.values.reduce(math.max);
    final entries = monthlyData.entries.toList();

    // Calculate trend direction
    String trendText = '';
    if (entries.length >= 2) {
      final last = entries.last.value;
      final prev = entries[entries.length - 2].value;
      if (prev > 0) {
        final change = ((last - prev) / prev * 100);
        if (change.abs() > 5) {
          trendText = change > 0 ? ' +${change.toStringAsFixed(0)}%' : ' ${change.toStringAsFixed(0)}%';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getCategoryIcon(category, theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatCategory(category),
                      style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatCurrencyCompact(total),
                    style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (trendText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        trendText,
                        style: theme.typography.sm.copyWith(
                          color: trendText.startsWith(' +') ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) {
                final barWidth = maxAmount > 0 ? entry.value / maxAmount : 0.0;
                final monthParts = entry.key.split('-');
                final monthLabel = '${monthParts[1]}/${monthParts[0].substring(2)}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(monthLabel, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
                      ),
                      Expanded(
                        child: _buildBar(theme, barWidth),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          formatCurrencyCompact(entry.value),
                          textAlign: TextAlign.right,
                          style: theme.typography.sm,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Shared Building Blocks ============

  Widget _buildSummaryStats(FThemeData theme, AnalysisState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(theme, 'Total', formatCurrencyCompact(state.totalSpending), FIcons.wallet)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(theme, 'Transactions', state.transactionCount.toString(), FIcons.receipt)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(theme, 'Average', formatCurrencyCompact(state.averageTransaction), FIcons.calculator)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(theme, 'Top Category', formatCategory(state.topCategory ?? 'N/A'), FIcons.tag)),
          ],
        ),
      ],
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
                Flexible(child: Text(label, style: theme.typography.sm, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.typography.xl2),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(FThemeData theme, String label, double amount, double barWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
          ),
          Expanded(child: _buildBar(theme, barWidth)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(formatCurrencyCompact(amount), textAlign: TextAlign.right, style: theme.typography.sm),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(FThemeData theme, String week, double amount, double barWidth, double? change) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(week, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Text(formatCurrencyCompact(amount), style: theme.typography.base.copyWith(fontWeight: FontWeight.w600)),
                      if (change != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (change > 0 ? Colors.red : Colors.green).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                            style: theme.typography.sm.copyWith(
                              color: change > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBar(theme, barWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientRow(FThemeData theme, int rank, String name, double amount, double barWidth, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank.',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(name, style: theme.typography.base, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildBar(theme, barWidth),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrencyCompact(amount), style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(FThemeData theme, double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: width.clamp(0.0, 1.0),
        backgroundColor: theme.colors.muted,
        minHeight: 8,
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
                  Text(formatCategory(category), style: theme.typography.base),
                ],
              ),
              Text(
                formatCurrencyCompact(amount),
                style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildBar(theme, percentage),
        ],
      ),
    );
  }

  Widget _buildInsightCard(FThemeData theme, InsightData insight) {
    final color = _insightColors[insight.type] ?? theme.colors.primary;
    final icon = _insightIcons[insight.icon] ?? FIcons.sparkles;

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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
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
    return Icon(_categoryIcons[category.toLowerCase()] ?? FIcons.circle, size: 18, color: theme.colors.primary);
  }

  Widget _buildBudgetProgressCard(FThemeData theme, BudgetState budgetState) {
    final pct = budgetState.overallPercentage;
    final color = pct >= 100 ? Colors.red : pct >= 75 ? Colors.orange : Colors.green;
    final remaining = budgetState.overallBudget - budgetState.currentMonthSpent;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(FIcons.target, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text('Monthly Budget', style: theme.typography.base.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showBudgetDialog(theme),
                  child: Icon(FIcons.settings, size: 16, color: theme.colors.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatCurrencyCompact(budgetState.currentMonthSpent)} / ${formatCurrencyCompact(budgetState.overallBudget)}',
                  style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: theme.typography.base.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: theme.colors.muted,
                color: color,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              remaining >= 0
                  ? '${formatCurrencyCompact(remaining)} remaining'
                  : '${formatCurrencyCompact(remaining.abs())} over budget',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetBars(FThemeData theme, BudgetState budgetState) {
    final entries = budgetState.categoryBudgets.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FIcons.layoutList, size: 18, color: theme.colors.primary),
                const SizedBox(width: 8),
                Text('Category Budgets', style: theme.typography.base.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final spent = budgetState.currentMonthByCategory[entry.key] ?? 0.0;
              final pct = (spent / entry.value * 100).clamp(0.0, 999.0);
              final barColor = pct >= 90 ? Colors.red : pct >= 75 ? Colors.orange : Colors.green;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _getCategoryIcon(entry.key, theme),
                            const SizedBox(width: 6),
                            Text(formatCategory(entry.key), style: theme.typography.sm),
                          ],
                        ),
                        Text(
                          '${formatCurrencyCompact(spent)} / ${formatCurrencyCompact(entry.value)} (${pct.toStringAsFixed(0)}%)',
                          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        backgroundColor: theme.colors.muted,
                        color: barColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetBudgetCard(FThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBudgetDialog(theme),
        borderRadius: theme.style.borderRadius,
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(FIcons.target, size: 18, color: theme.colors.mutedForeground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set a Budget', style: theme.typography.base.copyWith(fontWeight: FontWeight.w500)),
                      Text(
                        'Track monthly spending against a target',
                        style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
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
    );
  }

  void _showBudgetDialog(FThemeData theme) {
    final budgetState = ref.read(budgetProvider);
    final controller = TextEditingController(
      text: budgetState.overallBudget > 0 ? budgetState.overallBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly budget (baht)',
            prefixText: '฿ ',
            hintText: 'e.g. 15000',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              ref.read(budgetProvider.notifier).setOverallBudget(amount);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FThemeData theme) {
    return Center(
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
    );
  }

  Widget _buildNoDataForView(FThemeData theme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(FIcons.info, size: 32, color: theme.colors.mutedForeground),
            const SizedBox(height: 12),
            Text(message, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
