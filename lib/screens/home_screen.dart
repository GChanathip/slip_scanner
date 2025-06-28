import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
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
          MaterialPageRoute(
            builder: (context) => const ScanningProgressScreen(),
          ),
        );
        
        // Refresh data if scanning completed successfully
        if (result == true) {
          await _loadData();
          await _checkIfScannedBefore();
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo access denied. Please enable in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo library access is required to scan payment slips')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthTotal = _monthlyTotals[DateFormat('yyyy-MM').format(DateTime.now())] ?? 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Slip Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadData();
                await _checkIfScannedBefore();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan All Photos Card
                    Card(
                      elevation: 4,
                      color: Theme.of(context).primaryColor,
                      child: InkWell(
                        onTap: _startScanAllPhotos,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hasScannedBefore ? 'Scan New Photos' : 'Scan All Photos',
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Month Summary Card
                    if (_monthlyTotals.isNotEmpty) ...[
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month\'s Spending',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${currentMonthTotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MonthlyViewScreen(
                                        month: DateTime.now(),
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                child: const Text('View Details →'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Monthly Totals or Welcome Message
                    if (_monthlyTotals.isNotEmpty) ...[
                      Text(
                        'Monthly Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._monthlyTotals.entries.take(3).map((entry) {
                        final month = DateTime.parse('${entry.key}-01');
                        return ListTile(
                          title: Text(DateFormat('MMMM yyyy').format(month)),
                          trailing: Text(
                            '\$${entry.value.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MonthlyViewScreen(month: month),
                              ),
                            ).then((_) => _loadData());
                          },
                        );
                      }),
                      
                      const SizedBox(height: 24),
                    ] else ...[
                      // Welcome/Getting Started Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Getting Started',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome to Payment Slip Scanner! This app automatically finds and tracks payment slips in your photo library.',
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '• Tap "Scan All Photos" to start\n'
                                '• The app will find payment amounts and dates\n'
                                '• View your spending organized by month\n'
                                '• Delete slips to free up storage space',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Recent Slips
                    if (_recentSlips.isNotEmpty) ...[
                      Text(
                        'Recent Slips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._recentSlips.map((slip) {
                        return Card(
                          child: ListTile(
                            title: Text('\$${slip.amount.toStringAsFixed(2)}'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(slip.date)),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SlipDetailScreen(slip: slip),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}