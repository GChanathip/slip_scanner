import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:avers/core/database/database_service.dart';
import 'package:avers/core/models/category_registry.dart';
import 'package:avers/core/models/payment_slip.dart';
import 'package:avers/core/services/platform_service.dart';
import 'package:avers/core/utils/dialogs.dart';
import 'package:avers/core/utils/formatters.dart';
import 'package:avers/features/category/providers/category_provider.dart';
import 'package:avers/features/category/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

@RoutePage()
class SlipDetailScreen extends ConsumerStatefulWidget {
  final PaymentSlip slip;

  const SlipDetailScreen({super.key, required this.slip});

  @override
  ConsumerState<SlipDetailScreen> createState() => _SlipDetailScreenState();
}

class _SlipDetailScreenState extends ConsumerState<SlipDetailScreen> {
  Future<Uint8List?>? _assetImageFuture;
  late PaymentSlip _slip;

  // Edit mode state
  bool _isEditing = false;
  bool _isSaving = false;

  // Edit controllers
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  String _editCategory = 'other';
  bool _editRecurring = false;
  String _editFrequency = 'weekly';

  bool get _isManual => _slip.assetId?.startsWith('manual_') ?? false;

  bool get _hasChanges {
    if (!_isEditing) return false;
    return _recipientController.text.trim() != (_slip.recipientName ?? '') ||
        _notesController.text.trim() != (_slip.notes ?? '') ||
        _editCategory != (_slip.category ?? 'other') ||
        _editRecurring != _slip.isRecurring ||
        (_editRecurring && _editFrequency != (_slip.recurringFrequency ?? 'weekly')) ||
        (_isManual && _amountController.text.trim() != _slip.amount.toString());
  }

  @override
  void initState() {
    super.initState();
    _slip = widget.slip;
    if (_slip.imagePath.isNotEmpty && !_slip.imagePath.startsWith('/')) {
      _assetImageFuture = PlatformService.loadImageFromAsset(_slip.imagePath);
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _recipientController.text = _slip.recipientName ?? '';
      _notesController.text = _slip.notes ?? '';
      _amountController.text = _slip.amount.toString();
      _editCategory = _slip.category ?? 'other';
      _editRecurring = _slip.isRecurring;
      _editFrequency = _slip.recurringFrequency ?? 'weekly';
    });
  }

  Future<void> _cancelEdit() async {
    if (_hasChanges) {
      final discard = await showFDialog<bool>(
        context: context,
        builder: (dialogContext, style, animation) => FDialog(
          animation: animation,
          title: const Text('Discard changes?'),
          body: const Text('Your edits will not be saved.'),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep Editing'),
            ),
            FButton(
              variant: FButtonVariant.destructive,
              onPress: () => Navigator.pop(dialogContext, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final oldCategory = _slip.category;
    final oldCategorySource = _slip.categorySource;
    final categoryChanged = _editCategory != (oldCategory ?? 'other');
    final recipientName = _recipientController.text.trim();

    try {
      final fields = <String, dynamic>{
        'recipientName': recipientName.isEmpty ? null : recipientName,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'category': _editCategory,
        'isRecurring': _editRecurring,
        'recurringFrequency': _editRecurring ? _editFrequency : null,
      };

      // Set categorySource to 'user' when category is changed
      if (categoryChanged) {
        fields['categorySource'] = 'user';
      }

      if (_isManual) {
        final amt = double.tryParse(_amountController.text.replaceAll(',', ''));
        if (amt != null && amt > 0) fields['amount'] = amt;
      }
      await DatabaseService.updateSlipFields(_slip.id!, fields);

      // Create learning rule if category changed and recipient is present
      CategoryService? svc;
      if (categoryChanged && recipientName.isNotEmpty) {
        final db = await DatabaseService.database;
        svc = CategoryService(db);
        await svc.upsertRule(recipientName, _editCategory);
      }

      // Update local state with new values
      setState(() {
        _slip = _slip.copyWith(
          recipientName: fields['recipientName'] as String?,
          notes: fields['notes'] as String?,
          category: _editCategory,
          categorySource: categoryChanged ? 'user' : _slip.categorySource,
          isRecurring: _editRecurring,
          recurringFrequency: _editRecurring ? _editFrequency : null,
          amount: _isManual
              ? (double.tryParse(_amountController.text.replaceAll(',', '')) ??
                  _slip.amount)
              : null,
        );
        _isEditing = false;
      });

      // Invalidate category providers so counts refresh
      if (categoryChanged) {
        ref.invalidate(builtinCategoriesWithCountsProvider);
        ref.invalidate(customCategoriesWithCountsProvider);
      }

      if (mounted) {
        if (categoryChanged && recipientName.isNotEmpty) {
          // Show learning SnackBar with undo
          showFToast(
            context: context,
            duration: const Duration(seconds: 8),
            title: const Text('Got it!'),
            description: Text(
              "Future '$recipientName' transactions will be categorized as ${getCategoryLabel(_editCategory)}",
            ),
            suffixBuilder: (_, _) => FButton(
              variant: FButtonVariant.outline,
              onPress: () => _undoLearning(
                oldCategory: oldCategory,
                oldCategorySource: oldCategorySource,
                recipientName: recipientName,
              ),
              child: const Text('Undo'),
            ),
          );
        } else {
          showFToast(
            context: context,
            title: const Text('Saved'),
            description: const Text('Slip updated successfully'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Error'),
          description: Text('Failed to save: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _undoLearning({
    required String? oldCategory,
    required String? oldCategorySource,
    required String recipientName,
  }) async {
    try {
      // Revert category and categorySource in DB
      await DatabaseService.updateSlipFields(_slip.id!, {
        'category': oldCategory ?? 'other',
        'categorySource': oldCategorySource,
      });

      // Delete the learning rule
      final db = await DatabaseService.database;
      final svc = CategoryService(db);
      await svc.deleteRule(svc.normalizeRecipient(recipientName));

      setState(() {
        _slip = _slip.copyWith(
          category: oldCategory ?? 'other',
          categorySource: oldCategorySource,
        );
      });

      ref.invalidate(builtinCategoriesWithCountsProvider);
      ref.invalidate(customCategoriesWithCountsProvider);

      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Undone'),
          description: const Text('Category change undone'),
        );
      }
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Error'),
          description: Text('Failed to undo: $e'),
        );
      }
    }
  }

  Future<void> _deleteSlip(BuildContext context) async {
    if (!await showDeleteConfirmation(context)) return;

    try {
      await PlatformService.deleteSlipImage(_slip.imagePath);
      await DatabaseService.deletePaymentSlip(_slip.id!);

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
        showFToast(
          context: context,
          title: const Text('Error'),
          description: Text('Error deleting slip: $e'),
        );
      }
    }
  }

  Widget _buildStatusChip(FThemeData theme) {
    final String label;
    final Color bgColor;
    final Color fgColor;

    if (_slip.llmProcessingStatus == 'completed') {
      label = 'Verified';
      bgColor = Colors.green.withValues(alpha: 0.15);
      fgColor = Colors.green;
    } else if (_isManual) {
      label = 'Manual';
      bgColor = Colors.blue.withValues(alpha: 0.15);
      fgColor = Colors.blue;
    } else {
      label = 'Pending AI';
      bgColor = Colors.amber.withValues(alpha: 0.15);
      fgColor = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.typography.sm.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategorySourceBadge(FThemeData theme) {
    final source = _slip.categorySource;
    if (source == null) return const SizedBox.shrink();

    final String badgeLabel;
    if (source == 'ai' || source == 'rule') {
      badgeLabel = 'AI';
    } else if (source == 'user') {
      badgeLabel = 'You';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeLabel,
        style: theme.typography.xs.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLockedField(FThemeData theme, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: theme.typography.sm
                      .copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(FIcons.lock, size: 12, color: theme.colors.mutedForeground),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: theme.style.borderRadius,
              border: Border.all(color: theme.colors.border),
            ),
            child: Text(value, style: theme.typography.base),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCategory(FThemeData theme) {
    final categoryNames = ref.watch(allCategoryNamesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style:
                theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        categoryNames.when(
          data: (names) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names.map((cat) {
              final isSelected = _editCategory == cat;
              final isBuiltIn = isBuiltInCategory(cat);
              final label = isBuiltIn
                  ? getCategoryLabel(cat)
                  : cat[0].toUpperCase() + cat.substring(1);
              return GestureDetector(
                onTap: () => setState(() => _editCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.muted,
                    borderRadius: theme.style.borderRadius,
                    border: Border.all(
                      color: isSelected
                          ? theme.colors.primary
                          : theme.colors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: theme.typography.sm.copyWith(
                      color: isSelected
                          ? theme.colors.primaryForeground
                          : theme.colors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBuiltInCategorySlugs.map((cat) {
              final isSelected = _editCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _editCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.muted,
                    borderRadius: theme.style.borderRadius,
                    border: Border.all(
                      color: isSelected
                          ? theme.colors.primary
                          : theme.colors.border,
                    ),
                  ),
                  child: Text(
                    getCategoryLabel(cat),
                    style: theme.typography.sm.copyWith(
                      color: isSelected
                          ? theme.colors.primaryForeground
                          : theme.colors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          error: (_, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBuiltInCategorySlugs.map((cat) {
              final isSelected = _editCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _editCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.muted,
                    borderRadius: theme.style.borderRadius,
                    border: Border.all(
                      color: isSelected
                          ? theme.colors.primary
                          : theme.colors.border,
                    ),
                  ),
                  child: Text(
                    getCategoryLabel(cat),
                    style: theme.typography.sm.copyWith(
                      color: isSelected
                          ? theme.colors.primaryForeground
                          : theme.colors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(FThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status chip
        _buildStatusChip(theme),
        const SizedBox(height: 16),

        // Amount — editable for manual, locked for OCR
        if (_isManual) ...[
          Text('Amount',
              style: theme.typography.sm
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('฿',
                  style: theme.typography.xl2
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(
                      controller: _amountController),
                  hint: '0.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else
          _buildLockedField(theme, 'Amount', formatCurrency(_slip.amount)),

        // Locked fields
        _buildLockedField(
            theme,
            'Date',
            _slip.transactionTime != null
                ? '${DateFormat('MMMM dd, yyyy').format(_slip.date)} - ${_slip.transactionTime}'
                : DateFormat('MMMM dd, yyyy').format(_slip.date)),
        if (_slip.senderName != null)
          _buildLockedField(theme, 'Sender', _slip.senderName),
        if (_slip.senderAccount != null)
          _buildLockedField(
              theme, 'Sender Account', 'xxx-xxx${_slip.senderAccount}'),
        if (_slip.receiverAccount != null)
          _buildLockedField(
              theme, 'Receiver Account', 'xxx-xxx${_slip.receiverAccount}'),
        if (_slip.referenceId != null)
          _buildLockedField(theme, 'Reference ID', _slip.referenceId),

        // Editable: recipientName
        FTextField(
          control: FTextFieldControl.managed(controller: _recipientController),
          label: const Text('Recipient'),
          hint: 'Enter recipient name',
        ),
        const SizedBox(height: 16),

        // Editable: category chips
        _buildEditableCategory(theme),
        const SizedBox(height: 16),

        // Editable: notes
        FTextField(
          control: FTextFieldControl.managed(controller: _notesController),
          label: const Text('Notes'),
          hint: 'Add a note...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Editable: recurring toggle
        Row(
          children: [
            Expanded(
              child: Text('Recurring',
                  style: theme.typography.sm
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
            FSwitch(
              value: _editRecurring,
              onChange: (v) => setState(() => _editRecurring = v),
            ),
          ],
        ),

        if (_editRecurring) ...[
          const SizedBox(height: 12),
          Text('Frequency',
              style: theme.typography.sm
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          for (final freq in ['weekly', 'monthly', 'custom'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _editFrequency = freq),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    FRadio(
                      value: _editFrequency == freq,
                      onChange: (_) =>
                          setState(() => _editFrequency = freq),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      freq[0].toUpperCase() + freq.substring(1),
                      style: theme.typography.base,
                    ),
                  ],
                ),
              ),
            ),
        ],

        const SizedBox(height: 24),

        // Save button
        FButton(
          onPress: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildImagePreview(FThemeData theme) {
    final imagePath = _slip.imagePath;
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
      if (!File(imagePath).existsSync()) return const SizedBox.shrink();
      return buildColumn(
        Image.file(File(imagePath),
            height: 300, width: double.infinity, fit: BoxFit.contain),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _assetImageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildColumn(
            const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator())),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) return const SizedBox.shrink();
        return buildColumn(
          Image.memory(bytes,
              height: 300, width: double.infinity, fit: BoxFit.contain),
        );
      },
    );
  }

  Widget _buildViewMode(FThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Status chip
        _buildStatusChip(theme),
        const SizedBox(height: 16),

        // Amount Card
        FCard(
          title: const Text('Amount'),
          subtitle: Text(
            formatCurrency(_slip.amount),
            style: theme.typography.xl4.copyWith(
                fontWeight: FontWeight.bold, color: theme.colors.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Date Card
        FCard(
          title: const Text('Date'),
          subtitle: Text(
            _slip.transactionTime != null
                ? '${DateFormat('MMMM dd, yyyy').format(_slip.date)} - ${_slip.transactionTime}'
                : DateFormat('MMMM dd, yyyy').format(_slip.date),
            style: theme.typography.lg,
          ),
        ),
        const SizedBox(height: 16),

        // Sender Info
        if (_slip.senderName != null) ...[
          FCard(
            title: const Text('From'),
            subtitle: Text(_slip.senderName!, style: theme.typography.lg),
            child: _slip.senderAccount != null
                ? Text('Account: xxx-xxx${_slip.senderAccount}',
                    style: theme.typography.sm
                        .copyWith(color: theme.colors.mutedForeground))
                : null,
          ),
          const SizedBox(height: 16),
        ],

        // Receiver Info
        if (_slip.recipientName != null) ...[
          FCard(
            title: const Text('To'),
            subtitle:
                Text(_slip.recipientName!, style: theme.typography.lg),
            child: _slip.receiverAccount != null
                ? Text('Account: xxx-xxx${_slip.receiverAccount}',
                    style: theme.typography.sm
                        .copyWith(color: theme.colors.mutedForeground))
                : null,
          ),
          const SizedBox(height: 16),
        ],

        // Category with source badge
        if (_slip.category != null) ...[
          FCard(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Category'),
                _buildCategorySourceBadge(theme),
              ],
            ),
            subtitle: Text(formatCategory(_slip.category!),
                style: theme.typography.lg),
          ),
          const SizedBox(height: 16),
        ],

        // Recurring
        if (_slip.isRecurring) ...[
          FCard(
            title: const Text('Recurring'),
            subtitle: Text(
              _slip.recurringFrequency != null
                  ? _slip.recurringFrequency![0].toUpperCase() +
                      _slip.recurringFrequency!.substring(1)
                  : 'Yes',
              style: theme.typography.lg,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Notes
        if (_slip.notes != null) ...[
          FCard(
            title: const Text('Notes'),
            subtitle:
                Text(_slip.notes!, style: theme.typography.base),
          ),
          const SizedBox(height: 16),
        ],

        // Processing Status
        if (_slip.llmProcessingStatus != 'completed') ...[
          FCard(
            title: const Text('AI Processing'),
            subtitle: Text(
              switch (_slip.llmProcessingStatus) {
                'pending' => 'Pending analysis',
                'processing' => 'Analyzing...',
                'failed' =>
                  'Analysis failed (retry ${_slip.retryCount}/3)',
                _ => _slip.llmProcessingStatus,
              },
              style: theme.typography.sm.copyWith(
                color: _slip.llmProcessingStatus == 'failed'
                    ? theme.colors.destructive
                    : theme.colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Reference ID
        if (_slip.referenceId != null) ...[
          FCard(
            title: const Text('Reference ID'),
            subtitle: Text(_slip.referenceId!,
                style: theme.typography.base),
          ),
          const SizedBox(height: 16),
        ],

        // Image Preview
        _buildImagePreview(theme),

        // Extracted Text
        if (_slip.extractedText.isNotEmpty) ...[
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
              child: Text(_slip.extractedText,
                  style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Metadata
        FCard(
          title: const Text('Scanned on'),
          subtitle: Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(_slip.createdAt),
              style: theme.typography.base),
        ),

        const SizedBox(height: 24),

        // Delete Button (at bottom)
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => _deleteSlip(context),
          prefix: const Icon(FIcons.trash2, size: 16),
          child: const Text('Delete Slip'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FScaffold(
      header: FHeader.nested(
        title: Text(_isEditing ? 'Edit Slip' : 'Slip Details'),
        prefixes: [
          if (_isEditing)
            FHeaderAction(
              icon: const Icon(FIcons.x),
              onPress: _cancelEdit,
            )
          else
            FHeaderAction.back(
                onPress: () => context.router.maybePop()),
        ],
        suffixes: [
          if (!_isEditing)
            FHeaderAction(
              icon: const Icon(FIcons.pencil),
              onPress: _enterEditMode,
            ),
        ],
      ),
      child: _isEditing ? _buildEditMode(theme) : _buildViewMode(theme),
    );
  }
}
