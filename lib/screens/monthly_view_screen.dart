import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
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
    final confirm = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: (_) => style,
        animation: animation,
        direction: Axis.vertical,
        title: const Text('Delete Slip'),
        body: const Text('Are you sure you want to delete this payment slip?'),
        actions: [
          FButton(
            style: FButtonStyle.outline(),
            onPress: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
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
          showFToast(
            context: context,
            title: const Text('Success'),
            description: const Text('Slip deleted successfully'),
          );
        }
      } catch (e) {
        if (mounted) {
          showFToast(context: context, title: const Text('Error'), description: Text('Error deleting slip: $e'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final monthName = DateFormat('MMMM yyyy').format(widget.month);

    return FScaffold(
      header: FHeader.nested(
        title: Text(monthName),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.1),
                    border: Border(bottom: BorderSide(color: theme.colors.border, width: 1)),
                  ),
                  child: Column(
                    children: [
                      Text('Total Spending', style: theme.typography.lg),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: theme.typography.xl4.copyWith(fontWeight: FontWeight.bold, color: theme.colors.primary),
                      ),
                      Text(
                        '${_slips.length} slip${_slips.length != 1 ? 's' : ''}',
                        style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                      ),
                    ],
                  ),
                ),

                // Slips List
                Expanded(
                  child: _slips.isEmpty
                      ? Center(
                          child: Text(
                            'No payment slips for this month',
                            style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                          ),
                        )
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
                                    color: theme.colors.background,
                                    border: Border.all(color: theme.colors.border),
                                    borderRadius: theme.style.borderRadius,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: theme.colors.primary, shape: BoxShape.circle),
                                        child: Center(
                                          child: Text(
                                            '\$',
                                            style: TextStyle(
                                              color: theme.colors.primaryForeground,
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
                                              style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(slip.date),
                                              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FButton(
                                        style: FButtonStyle.destructive(),
                                        onPress: () => _deleteSlip(slip),
                                        prefix: Icon(FIcons.trash2, size: 16),
                                        child: const Text('Delete'),
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
