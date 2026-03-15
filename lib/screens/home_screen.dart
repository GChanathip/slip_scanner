import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monthly_summary.dart';
import '../models/payment_slip.dart';
import '../providers/budget_provider.dart';
import '../providers/budget_state.dart';
import '../router/app_router.dart';
import '../services/database_service.dart';
import '../services/monthly_summary_service.dart';
import '../providers/scanning_provider.dart';
import '../providers/extraction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/hero_card.dart';
import '../widgets/slip_list_tile.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<PaymentSlip> _recentSlips = [];
  Map<String, double> _monthlyTotals = {};
  bool _isLoading = false;
  bool _hasScannedBefore = false;
  MonthlySummary? _monthlySummary;
  bool _summaryDismissed = false;
  bool _summaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkIfScannedBefore();
    _loadMonthlySummary();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseService.getPaymentSlips(),
        DatabaseService.getMonthlyTotals(),
      ]);
      setState(() {
        _recentSlips = (results[0] as List<PaymentSlip>).take(5).toList();
        _monthlyTotals = results[1] as Map<String, double>;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlySummary() async {
    final summary = await MonthlySummaryService.instance.checkAndGenerate();
    if (summary == null) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('summary_dismissed_${summary.month}') ?? false;
    if (mounted) {
      setState(() {
        _monthlySummary = summary;
        _summaryDismissed = dismissed;
      });
    }
  }

  Future<void> _dismissSummary() async {
    if (_monthlySummary == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('summary_dismissed_${_monthlySummary!.month}', true);
    setState(() => _summaryDismissed = true);
  }

  Future<void> _checkIfScannedBefore() async {
    final processedIds = await DatabaseService.getProcessedAssetIds();
    setState(() {
      _hasScannedBefore = processedIds.isNotEmpty;
    });
  }

  Widget _buildBudgetProgress(FThemeData theme, BudgetState budgetState) {
    final pct = budgetState.overallPercentage;
    final color = pct >= 100 ? Colors.red : pct >= 75 ? Colors.orange : Colors.green;
    return GestureDetector(
      onTap: () => context.router.push(const AnalysisRoute()),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colors.muted,
          borderRadius: theme.style.borderRadius,
          border: Border.all(color: theme.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(FIcons.target, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text('Budget', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(
                  '${formatCurrencyCompact(budgetState.currentMonthSpent)} / ${formatCurrencyCompact(budgetState.overallBudget)} (${pct.toStringAsFixed(0)}%)',
                  style: theme.typography.sm.copyWith(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: theme.colors.background,
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(FThemeData theme, MonthlySummary summary) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.parse('${summary.month}-01'));
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(FIcons.sparkles, size: 18, color: theme.colors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Your $monthLabel summary is ready',
                          style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismissSummary,
                  child: Icon(FIcons.x, size: 16, color: theme.colors.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatCurrencyCompact(summary.totalSpent)}${summary.budgetTarget > 0 ? ' / ${formatCurrencyCompact(summary.budgetTarget)} budget' : ' spent'}',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
            ),
            if (_summaryExpanded) ...[
              const SizedBox(height: 12),
              Text(summary.narrative, style: theme.typography.sm),
              if (summary.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...(summary.categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatCategory(e.key), style: theme.typography.sm),
                              Text(formatCurrencyCompact(e.value),
                                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )),
              ],
            ],
            const SizedBox(height: 8),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: () => setState(() => _summaryExpanded = !_summaryExpanded),
              mainAxisSize: MainAxisSize.min,
              suffix: Icon(_summaryExpanded ? FIcons.chevronUp : FIcons.chevronDown, size: 14),
              child: Text(_summaryExpanded ? 'Show less' : 'View details'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScanAllPhotos() async {
    // Check if already scanning
    final scanningState = ref.read(scanningProvider);
    if (scanningState.isScanning) {
      // Already scanning - just navigate to progress screen
      if (mounted) {
        final result = await context.router.push<bool>(const ScanningProgressRoute());

        // Refresh data if scanning completed successfully
        if (result == true) {
          await _loadData();
          await _checkIfScannedBefore();
        }
      }
      return;
    }

    // Check photo library permission
    PermissionStatus status = await Permission.photos.status;

    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      if (mounted) {
        final result = await context.router.push<bool>(const ScanningProgressRoute());

        // Refresh data if scanning completed successfully
        if (result == true) {
          await _loadData();
          await _checkIfScannedBefore();
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Photo Access Denied'),
          description: const Text('Please enable photo access in Settings.'),
        );
      }
    } else {
      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Permission Required'),
          description: const Text('Photo library access is required to scan payment slips'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final currentMonthTotal = _monthlyTotals[DateFormat('yyyy-MM').format(DateTime.now())] ?? 0.0;
    final budgetState = ref.watch(budgetProvider);

    return FScaffold(
      header: const FHeader(title: Text('Payment Slip Scanner')),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadData();
                await _checkIfScannedBefore();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  HeroCard(
                    onTap: _startScanAllPhotos,
                    color: theme.colors.primary,
                    foregroundColor: theme.colors.primaryForeground,
                    icon: FIcons.images,
                    title: _hasScannedBefore ? 'Scan New Photos' : 'Scan All Photos',
                    subtitle: _hasScannedBefore
                        ? 'Find new payment slips in your photos'
                        : 'Automatically find payment slips in your photo library',
                  ),

                  const SizedBox(height: 12),

                  HeroCard(
                    onTap: () => context.router.push(const AnalysisRoute()),
                    color: theme.colors.secondary,
                    foregroundColor: theme.colors.secondaryForeground,
                    icon: FIcons.sparkles,
                    title: 'AI Expense Analysis',
                    subtitle: 'Get insights and chat with AI about your spending',
                  ),

                  // Background processing indicator
                  Builder(
                    builder: (context) {
                      final extractionState = ref.watch(extractionQueueProvider);
                      if (extractionState.hasPending) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: theme.style.borderRadius,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(theme.colors.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${extractionState.pendingCount} slips pending AI analysis',
                                  style: theme.typography.sm,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Budget progress
                  if (budgetState.hasBudget) ...[
                    const SizedBox(height: 12),
                    _buildBudgetProgress(theme, budgetState),
                  ],

                  const SizedBox(height: 24),

                  // Monthly summary banner
                  if (_monthlySummary != null && !_summaryDismissed) ...[
                    _buildSummaryBanner(theme, _monthlySummary!),
                    const SizedBox(height: 16),
                  ],

                  // Current Month Summary Card
                  if (_monthlyTotals.isNotEmpty) ...[
                    FCard(
                      title: const Text("This Month's Spending"),
                      subtitle: Text(
                        formatCurrency(currentMonthTotal),
                        style: theme.typography.xl4.copyWith(color: theme.colors.primary, fontWeight: FontWeight.bold),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FButton(
                          variant: FButtonVariant.ghost,
                          onPress: () {
                            context.router.push(MonthlyViewRoute(month: DateTime.now())).then((_) => _loadData());
                          },
                          mainAxisSize: MainAxisSize.min,
                          suffix: Icon(FIcons.arrowRight, size: 16),
                          child: const Text('View Details'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Monthly Totals or Welcome Message
                  if (_monthlyTotals.isNotEmpty) ...[
                    Text('Monthly Summary', style: theme.typography.xl2),
                    const SizedBox(height: 8),
                    ..._monthlyTotals.entries.take(3).map((entry) {
                      final month = DateTime.parse('${entry.key}-01');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Material(
                          color: theme.colors.background,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: theme.colors.border),
                            borderRadius: theme.style.borderRadius,
                          ),
                          child: InkWell(
                            onTap: () {
                              context.router.push(MonthlyViewRoute(month: month)).then((_) => _loadData());
                            },
                            borderRadius: theme.style.borderRadius,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('MMMM yyyy').format(month), style: theme.typography.base),
                                  Text(
                                    formatCurrency(entry.value),
                                    style: theme.typography.base.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Welcome/Getting Started Section
                    FAlert(
                      icon: Icon(FIcons.lightbulb, color: theme.colors.primary),
                      title: const Text('Getting Started'),
                      subtitle: const Text(
                        'Welcome to Payment Slip Scanner! This app automatically finds and tracks payment slips in your photo library.\n\n'
                        '• Tap "Scan All Photos" to start\n'
                        '• The app will find payment amounts and dates\n'
                        '• View your spending organized by month\n'
                        '• Delete slips to free up storage space',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Slips
                  if (_recentSlips.isNotEmpty) ...[
                    Text('Recent Slips', style: theme.typography.xl2),
                    const SizedBox(height: 8),
                    ..._recentSlips.map((slip) => SlipListTile(
                          slip: slip,
                          onTap: () => context.router.push(SlipDetailRoute(slip: slip)).then((_) => _loadData()),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
