import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';

class SlipListTile extends StatelessWidget {
  final PaymentSlip slip;
  final VoidCallback onTap;
  final Widget? trailing;

  const SlipListTile({
    super.key,
    required this.slip,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: onTap,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '฿${slip.amount.toStringAsFixed(2)}',
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(slip.date),
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(FIcons.chevronRight, size: 20, color: theme.colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
