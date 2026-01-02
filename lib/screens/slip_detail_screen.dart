import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import '../services/platform_service.dart';

class SlipDetailScreen extends StatelessWidget {
  final PaymentSlip slip;

  const SlipDetailScreen({super.key, required this.slip});

  Future<void> _deleteSlip(BuildContext context) async {
    final confirm = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete Slip'),
        description: const Text('Are you sure you want to delete this payment slip?'),
        actions: [
          ShadButton.outline(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ShadButton.destructive(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PlatformService.deleteSlipImage(slip.imagePath);
        await DatabaseService.deletePaymentSlip(slip.id!);

        if (context.mounted) {
          Navigator.pop(context);
          ShadSonner.of(
            context,
          ).show(const ShadToast(title: Text('Success'), description: Text('Slip deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Details'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.foreground,
        actions: [
          ShadButton.destructive(
            size: ShadButtonSize.sm,
            onPressed: () => _deleteSlip(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(LucideIcons.trash2, size: 16), const SizedBox(width: 4), const Text('Delete')],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: theme.colorScheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Amount Card
          ShadCard(
            title: const Text('Amount'),
            description: Text(
              '\$${slip.amount.toStringAsFixed(2)}',
              style: theme.textTheme.h1.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Date Card
          ShadCard(
            title: const Text('Date'),
            description: Text(DateFormat('MMMM dd, yyyy').format(slip.date), style: theme.textTheme.large),
          ),
          const SizedBox(height: 16),

          // Image Preview
          if (File(slip.imagePath).existsSync()) ...[
            Text('Receipt Image', style: theme.textTheme.h3),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: theme.radius,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(File(slip.imagePath), height: 300, width: double.infinity, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
          ],

          // Extracted Text
          if (slip.extractedText.isNotEmpty) ...[
            Text('Extracted Text', style: theme.textTheme.h3),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: theme.radius,
              ),
              child: SingleChildScrollView(
                child: Text(slip.extractedText, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Metadata
          ShadCard(
            title: const Text('Scanned on'),
            description: Text(DateFormat('MMM dd, yyyy hh:mm a').format(slip.createdAt), style: theme.textTheme.p),
          ),
        ],
      ),
    );
  }
}
