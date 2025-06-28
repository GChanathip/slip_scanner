import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import '../services/platform_service.dart';
import 'slip_detail_screen.dart';

class MonthlyViewScreen extends StatefulWidget {
  final DateTime month;

  const MonthlyViewScreen({super.key, required this.month});

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends State<MonthlyViewScreen> {
  List<PaymentSlip> _slips = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlips();
  }

  Future<void> _loadSlips() async {
    setState(() => _isLoading = true);
    final slips = await DatabaseService.getPaymentSlipsByMonth(widget.month);
    double total = slips.fold(0, (sum, slip) => sum + slip.amount);
    setState(() {
      _slips = slips;
      _totalAmount = total;
      _isLoading = false;
    });
  }

  Future<void> _deleteSlip(PaymentSlip slip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slip'),
        content: const Text('Are you sure you want to delete this payment slip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PlatformService.deleteSlipImage(slip.imagePath);
        await DatabaseService.deletePaymentSlip(slip.id!);
        await _loadSlips();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slip deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting slip: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(widget.month);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(monthName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    children: [
                      Text(
                        'Total Spending',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_slips.length} slip${_slips.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                
                // Slips List
                Expanded(
                  child: _slips.isEmpty
                      ? const Center(
                          child: Text('No payment slips for this month'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _slips.length,
                          itemBuilder: (context, index) {
                            final slip = _slips[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    '\$',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '\$${slip.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  DateFormat('MMM dd, yyyy').format(slip.date),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSlip(slip),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SlipDetailScreen(slip: slip),
                                    ),
                                  ).then((_) => _loadSlips());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}