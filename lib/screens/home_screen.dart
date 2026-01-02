import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import 'monthly_view_screen.dart';
import 'slip_detail_screen.dart';
import 'scanning_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    // Check photo library permission
    PermissionStatus status = await Permission.photos.status;

    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const ScanningProgressScreen()),
        );

        // Refresh data if scanning completed successfully
        if (result == true) {
          await _loadData();
          await _checkIfScannedBefore();
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast(
            title: const Text('Photo Access Denied'),
            description: const Text('Please enable photo access in Settings.'),
            action: ShadButton.ghost(child: const Text('Settings'), onPressed: () => openAppSettings()),
          ),
        );
      }
    } else {
      if (mounted) {
        ShadSonner.of(context).show(
          const ShadToast(
            title: Text('Permission Required'),
            description: Text('Photo library access is required to scan payment slips'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currentMonthTotal = _monthlyTotals[DateFormat('yyyy-MM').format(DateTime.now())] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Slip Scanner'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.foreground,
      ),
      backgroundColor: theme.colorScheme.background,
      body: _isLoading
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
                  // Scan All Photos Card - Use GestureDetector + ShadCard
                  GestureDetector(
                    onTap: _startScanAllPhotos,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: theme.radius,
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
                            child: Icon(LucideIcons.images, color: theme.colorScheme.primaryForeground, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasScannedBefore ? 'Scan New Photos' : 'Scan All Photos',
                                  style: TextStyle(
                                    color: theme.colorScheme.primaryForeground,
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
                                    color: theme.colorScheme.primaryForeground.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.arrowRight, color: theme.colorScheme.primaryForeground),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Current Month Summary Card
                  if (_monthlyTotals.isNotEmpty) ...[
                    ShadCard(
                      title: const Text("This Month's Spending"),
                      description: Text(
                        '\$${currentMonthTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.h1.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      footer: ShadButton.ghost(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MonthlyViewScreen(month: DateTime.now())),
                          ).then((_) => _loadData());
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('View Details'),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.arrowRight, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Monthly Totals or Welcome Message
                  if (_monthlyTotals.isNotEmpty) ...[
                    Text('Monthly Summary', style: theme.textTheme.h3),
                    const SizedBox(height: 8),
                    ..._monthlyTotals.entries.take(3).map((entry) {
                      final month = DateTime.parse('${entry.key}-01');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MonthlyViewScreen(month: month)),
                            ).then((_) => _loadData());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.border),
                              borderRadius: theme.radius,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMMM yyyy').format(month), style: theme.textTheme.p),
                                Text(
                                  '\$${entry.value.toStringAsFixed(2)}',
                                  style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
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
                    ShadAlert(
                      icon: Icon(LucideIcons.lightbulb, color: theme.colorScheme.primary),
                      title: const Text('Getting Started'),
                      description: const Text(
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
                    Text('Recent Slips', style: theme.textTheme.h3),
                    const SizedBox(height: 8),
                    ..._recentSlips.map((slip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SlipDetailScreen(slip: slip)),
                            ).then((_) => _loadData());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.card,
                              border: Border.all(color: theme.colorScheme.border),
                              borderRadius: theme.radius,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${slip.amount.toStringAsFixed(2)}',
                                      style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('MMM dd, yyyy').format(slip.date), style: theme.textTheme.muted),
                                  ],
                                ),
                                Icon(LucideIcons.chevronRight, size: 20, color: theme.colorScheme.mutedForeground),
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
