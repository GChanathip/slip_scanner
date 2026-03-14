import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';
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

class SlipListTile extends StatelessWidget {
  final PaymentSlip slip;
  final VoidCallback onTap;

  const SlipListTile({
    super.key,
    required this.slip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final categoryIcon = _categoryIcons[slip.category?.toLowerCase()] ?? FIcons.circle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Semantics(
        button: true,
        label: 'Payment slip ${formatCurrency(slip.amount)}',
        child: Material(
          color: theme.colors.background,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.colors.border),
            borderRadius: theme.style.borderRadius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: theme.style.borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon, size: 20, color: theme.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatCurrency(slip.amount),
                          style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (slip.recipientName != null) slip.recipientName!,
                            DateFormat('MMM dd, yyyy').format(slip.date),
                          ].join(' · '),
                          style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(FIcons.chevronRight, size: 20, color: theme.colors.mutedForeground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
