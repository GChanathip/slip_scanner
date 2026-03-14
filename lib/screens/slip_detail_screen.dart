import 'dart:io';
import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';
import '../services/platform_service.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';

@RoutePage()
class SlipDetailScreen extends StatefulWidget {
  final PaymentSlip slip;

  const SlipDetailScreen({super.key, required this.slip});

  @override
  State<SlipDetailScreen> createState() => _SlipDetailScreenState();
}

class _SlipDetailScreenState extends State<SlipDetailScreen> {
  Future<Uint8List?>? _assetImageFuture;

  @override
  void initState() {
    super.initState();
    // Only load via platform channel if imagePath is not a real file path
    if (widget.slip.imagePath.isNotEmpty && !widget.slip.imagePath.startsWith('/')) {
      _assetImageFuture = PlatformService.loadImageFromAsset(widget.slip.imagePath);
    }
  }

  Future<void> _deleteSlip(BuildContext context) async {
    if (!await showDeleteConfirmation(context)) return;

    try {
      await PlatformService.deleteSlipImage(widget.slip.imagePath);
      await DatabaseService.deletePaymentSlip(widget.slip.id!);

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

  Widget _buildImagePreview(FThemeData theme) {
    final imagePath = widget.slip.imagePath;
    if (imagePath.isEmpty) return const SizedBox.shrink();

    final decoration = BoxDecoration(
      border: Border.all(color: theme.colors.border),
      borderRadius: theme.style.borderRadius,
    );

    Widget wrapImage(Widget child) => Container(
          decoration: decoration,
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    Column buildColumn(Widget imageWidget) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Image', style: theme.typography.xl2),
            const SizedBox(height: 8),
            wrapImage(imageWidget),
            const SizedBox(height: 16),
          ],
        );

    if (imagePath.startsWith('/')) {
      // Real file path (single-scanned slip)
      if (!File(imagePath).existsSync()) return const SizedBox.shrink();
      return buildColumn(
        Image.file(File(imagePath), height: 300, width: double.infinity, fit: BoxFit.contain),
      );
    }

    // PHAsset identifier (batch-scanned slip) — load on demand
    return FutureBuilder<Uint8List?>(
      future: _assetImageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildColumn(
            const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) return const SizedBox.shrink();
        return buildColumn(
          Image.memory(bytes, height: 300, width: double.infinity, fit: BoxFit.contain),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final slip = widget.slip;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Slip Details'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Amount Card
          FCard(
            title: const Text('Amount'),
            subtitle: Text(
              formatCurrency(slip.amount),
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

          // Category
          if (slip.category != null) ...[
            FCard(
              title: const Text('Category'),
              subtitle: Text(formatCategory(slip.category!), style: theme.typography.lg),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (slip.notes != null) ...[
            FCard(
              title: const Text('Notes'),
              subtitle: Text(slip.notes!, style: theme.typography.base),
            ),
            const SizedBox(height: 16),
          ],

          // Processing Status
          if (slip.llmProcessingStatus != 'completed') ...[
            FCard(
              title: const Text('AI Processing'),
              subtitle: Text(
                switch (slip.llmProcessingStatus) {
                  'pending' => 'Pending analysis',
                  'processing' => 'Analyzing...',
                  'failed' => 'Analysis failed (retry ${slip.retryCount}/3)',
                  _ => slip.llmProcessingStatus,
                },
                style: theme.typography.sm.copyWith(
                  color: slip.llmProcessingStatus == 'failed' ? theme.colors.destructive : theme.colors.mutedForeground,
                ),
              ),
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
          _buildImagePreview(theme),

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

          const SizedBox(height: 24),

          // Delete Button (at bottom)
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => _deleteSlip(context),
            prefix: Icon(FIcons.trash2, size: 16),
            child: const Text('Delete Slip'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
