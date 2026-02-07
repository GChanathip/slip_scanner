import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import '../services/platform_service.dart';
import '../utils/dialogs.dart';

@RoutePage()
class SlipDetailScreen extends StatelessWidget {
  final PaymentSlip slip;

  const SlipDetailScreen({super.key, required this.slip});

  Future<void> _deleteSlip(BuildContext context) async {
    if (!await showDeleteConfirmation(context)) return;

    try {
      await PlatformService.deleteSlipImage(slip.imagePath);
      await DatabaseService.deletePaymentSlip(slip.id!);

      if (context.mounted) {
        context.router.maybePop();
        showFToast(
          context: context,
          title: const Text('Success'),
          description: const Text('Slip deleted successfully'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFToast(context: context, title: const Text('Error'), description: Text('Error deleting slip: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Slip Details'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
        suffixes: [FHeaderAction(icon: const Icon(FIcons.trash2), onPress: () => _deleteSlip(context))],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Amount Card
          FCard(
            title: const Text('Amount'),
            subtitle: Text(
              '฿${slip.amount.toStringAsFixed(2)}',
              style: theme.typography.xl4.copyWith(fontWeight: FontWeight.bold, color: theme.colors.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Date Card
          FCard(
            title: const Text('Date'),
            subtitle: Text(
              slip.transactionTime != null
                  ? '${DateFormat('MMMM dd, yyyy').format(slip.date)} - ${slip.transactionTime}'
                  : DateFormat('MMMM dd, yyyy').format(slip.date),
              style: theme.typography.lg,
            ),
          ),
          const SizedBox(height: 16),

          // Sender Info
          if (slip.senderName != null) ...[
            FCard(
              title: const Text('From'),
              subtitle: Text(slip.senderName!, style: theme.typography.lg),
              child: slip.senderAccount != null
                  ? Text('Account: xxx-xxx${slip.senderAccount}', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground))
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          // Receiver Info
          if (slip.recipientName != null) ...[
            FCard(
              title: const Text('To'),
              subtitle: Text(slip.recipientName!, style: theme.typography.lg),
              child: slip.receiverAccount != null
                  ? Text('Account: xxx-xxx${slip.receiverAccount}', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground))
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          // Reference ID
          if (slip.referenceId != null) ...[
            FCard(
              title: const Text('Reference ID'),
              subtitle: Text(slip.referenceId!, style: theme.typography.base),
            ),
            const SizedBox(height: 16),
          ],

          // Image Preview
          if (File(slip.imagePath).existsSync()) ...[
            Text('Receipt Image', style: theme.typography.xl2),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colors.border),
                borderRadius: theme.style.borderRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(File(slip.imagePath), height: 300, width: double.infinity, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
          ],

          // Extracted Text
          if (slip.extractedText.isNotEmpty) ...[
            Text('Extracted Text', style: theme.typography.xl2),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: theme.colors.background,
                border: Border.all(color: theme.colors.border),
                borderRadius: theme.style.borderRadius,
              ),
              child: SingleChildScrollView(
                child: Text(slip.extractedText, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Metadata
          FCard(
            title: const Text('Scanned on'),
            subtitle: Text(DateFormat('MMM dd, yyyy hh:mm a').format(slip.createdAt), style: theme.typography.base),
          ),
        ],
      ),
    );
  }
}
