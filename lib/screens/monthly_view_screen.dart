import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/payment_slip.dart';
import '../router/app_router.dart';
import '../services/database_service.dart';
import '../services/platform_service.dart';

@RoutePage()
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
    final confirm = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Delete Slip'),
        description: const Text('Are you sure you want to delete this payment slip?'),
        actions: [
          ShadButton.outline(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ShadButton.destructive(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PlatformService.deleteSlipImage(slip.imagePath);
        await DatabaseService.deletePaymentSlip(slip.id!);
        await _loadSlips();

        if (mounted) {
          ShadSonner.of(
            context,
          ).show(const ShadToast(title: Text('Success'), description: Text('Slip deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ShadSonner.of(
            context,
          ).show(ShadToast(title: const Text('Error'), description: Text('Error deleting slip: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(widget.month);

    return Scaffold(
      appBar: AppBar(
        title: Text(monthName),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.foreground,
      ),
      backgroundColor: theme.colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    border: Border(bottom: BorderSide(color: theme.colorScheme.border, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Text('Total Spending', style: theme.textTheme.large),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text('${_slips.length} slip${_slips.length != 1 ? 's' : ''}', style: theme.textTheme.muted),
                    ],
                  ),
                ),

                // Slips List
                Expanded(
                  child: _slips.isEmpty
                      ? Center(child: Text('No payment slips for this month', style: theme.textTheme.muted))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _slips.length,
                          itemBuilder: (context, index) {
                            final slip = _slips[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  context.router.push(SlipDetailRoute(slip: slip)).then((_) => _loadSlips());
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
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '\$',
                                            style: TextStyle(
                                              color: theme.colorScheme.primaryForeground,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '\$${slip.amount.toStringAsFixed(2)}',
                                              style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(slip.date),
                                              style: theme.textTheme.muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ShadButton.destructive(
                                        size: ShadButtonSize.sm,
                                        onPressed: () => _deleteSlip(slip),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.trash2, size: 16),
                                            const SizedBox(width: 4),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
