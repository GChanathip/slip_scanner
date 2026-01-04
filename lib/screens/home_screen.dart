import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';
import '../router/app_router.dart';
import '../services/database_service.dart';
import '../providers/scanning_provider.dart';
import '../providers/extraction_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkIfScannedBefore();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final slips = await DatabaseService.getPaymentSlips();
      final totals = await DatabaseService.getMonthlyTotals();
      setState(() {
        _recentSlips = slips.take(5).toList();
        _monthlyTotals = totals;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfScannedBefore() async {
    final processedIds = await DatabaseService.getProcessedAssetIds();
    setState(() {
      _hasScannedBefore = processedIds.isNotEmpty;
    });
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
                  // Scan All Photos Card - Use GestureDetector + Container
                  GestureDetector(
                    onTap: _startScanAllPhotos,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colors.primary, theme.colors.primary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: theme.style.borderRadius,
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(FIcons.images, color: theme.colors.primaryForeground, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasScannedBefore ? 'Scan New Photos' : 'Scan All Photos',
                                  style: TextStyle(
                                    color: theme.colors.primaryForeground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hasScannedBefore
                                      ? 'Find new payment slips in your photos'
                                      : 'Automatically find payment slips in your photo library',
                                  style: TextStyle(
                                    color: theme.colors.primaryForeground.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(FIcons.arrowRight, color: theme.colors.primaryForeground),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Analyze Expenses Card
                  GestureDetector(
                    onTap: () => context.router.push(const AnalysisRoute()),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colors.secondary, theme.colors.secondary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: theme.style.borderRadius,
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colors.secondaryForeground.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(FIcons.sparkles, color: theme.colors.secondaryForeground, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Expense Analysis',
                                  style: TextStyle(
                                    color: theme.colors.secondaryForeground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get insights and chat with AI about your spending',
                                  style: TextStyle(
                                    color: theme.colors.secondaryForeground.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(FIcons.arrowRight, color: theme.colors.secondaryForeground),
                        ],
                      ),
                    ),
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

                  const SizedBox(height: 24),

                  // Current Month Summary Card
                  if (_monthlyTotals.isNotEmpty) ...[
                    FCard(
                      title: const Text("This Month's Spending"),
                      subtitle: Text(
                        '\$${currentMonthTotal.toStringAsFixed(2)}',
                        style: theme.typography.xl4.copyWith(color: theme.colors.primary, fontWeight: FontWeight.bold),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FButton(
                          style: FButtonStyle.ghost(),
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
                        child: GestureDetector(
                          onTap: () {
                            context.router.push(MonthlyViewRoute(month: month)).then((_) => _loadData());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colors.border),
                              borderRadius: theme.style.borderRadius,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMMM yyyy').format(month), style: theme.typography.base),
                                Text(
                                  '\$${entry.value.toStringAsFixed(2)}',
                                  style: theme.typography.base.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
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
                    ..._recentSlips.map((slip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            context.router.push(SlipDetailRoute(slip: slip)).then((_) => _loadData());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colors.background,
                              border: Border.all(color: theme.colors.border),
                              borderRadius: theme.style.borderRadius,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${slip.amount.toStringAsFixed(2)}',
                                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(slip.date),
                                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                                    ),
                                  ],
                                ),
                                Icon(FIcons.chevronRight, size: 20, color: theme.colors.mutedForeground),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}
