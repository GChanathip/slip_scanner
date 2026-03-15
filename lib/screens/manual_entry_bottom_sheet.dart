import 'dart:math';

import 'package:flutter/material.dart' show CircularProgressIndicator, Colors, DraggableScrollableSheet, showDatePicker;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_registry.dart';
import '../models/payment_slip.dart';
import '../services/database_service.dart';

String _uniqueId() {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final rand = Random().nextInt(999999).toString().padLeft(6, '0');
  return '${ts}_$rand';
}

/// Shows the manual expense entry bottom sheet.
/// Returns `true` if a slip was saved, `null`/`false` otherwise.
Future<bool?> showManualEntrySheet(BuildContext context) {
  return showFSheet<bool>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: null,
    builder: (context) => const ManualEntryBottomSheet(),
  );
}

class ManualEntryBottomSheet extends StatefulWidget {
  const ManualEntryBottomSheet({super.key});

  @override
  State<ManualEntryBottomSheet> createState() => _ManualEntryBottomSheetState();
}

class _ManualEntryBottomSheetState extends State<ManualEntryBottomSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountFocus = FocusNode();

  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _frequency = 'weekly';
  bool _isSaving = false;
  List<String> _recentRecipients = [];
  String _recipientText = '';

  bool get _hasData =>
      _amountController.text.isNotEmpty ||
      _recipientText.isNotEmpty ||
      _notesController.text.isNotEmpty;

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadLastCategory();
    _loadRecentRecipients();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  Future<void> _loadLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_used_category') ?? 'food';
    if (mounted) setState(() => _selectedCategory = last);
  }

  Future<void> _loadRecentRecipients() async {
    final now = DateTime.now();
    final recipients = await DatabaseService.getTopRecipients(
      now.subtract(const Duration(days: 365)),
      now,
      limit: 5,
    );
    if (mounted) {
      setState(() => _recentRecipients = recipients.keys.toList());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasData) return true;
    final result = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        direction: Axis.vertical,
        title: const Text('Discard this entry?'),
        body: const Text('Your unsaved expense will be lost.'),
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
    return result == true;
  }

  Future<void> _save() async {
    if (_amount <= 0 || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final slip = PaymentSlip(
        imagePath: '',
        assetId: 'manual_${_uniqueId()}',
        amount: _amount,
        date: _selectedDate,
        extractedText: '',
        createdAt: DateTime.now(),
        recipientName:
            _recipientText.trim().isEmpty ? null : _recipientText.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        category: _selectedCategory,
        llmProcessingStatus: 'completed',
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _frequency : null,
      );
      await DatabaseService.insertPaymentSlipsBatch([slip]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_used_category', _selectedCategory);
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _dateChipLabel(DateTime date) {
    final today = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    switch (diff) {
      case 0:
        return 'Today';
      case 1:
        return 'Yesterday';
      case 2:
        return '2 days ago';
      case 3:
        return '3 days ago';
      default:
        return DateFormat('d MMM').format(date);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _confirmDiscard();
        if (canPop && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.25,
        expand: false,
        builder: (context, scrollController) =>
            _buildContent(theme, scrollController),
      ),
    );
  }

  Widget _buildContent(FThemeData theme, ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHandle(theme),
          _buildHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountField(theme),
                  const SizedBox(height: 20),
                  _buildCategorySection(theme),
                  const SizedBox(height: 20),
                  _buildRecipientField(),
                  const SizedBox(height: 20),
                  _buildDateSection(theme),
                  const SizedBox(height: 20),
                  _buildNotesField(),
                  if (_isRecurring) ...[
                    const SizedBox(height: 20),
                    _buildFrequencySection(theme),
                  ],
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHandle(FThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          Text(
            'Add Expense',
            style:
                theme.typography.xl.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          FButton.icon(
            variant: FButtonVariant.ghost,
            onPress: () async {
              if (await _confirmDiscard() && mounted) Navigator.pop(context);
            },
            child: Icon(FIcons.x, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '฿',
              style: theme.typography.xl4.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                control: FTextFieldControl.managed(
                    controller: _amountController),
                hint: '0.00',
                focusNode: _amountFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBuiltInCategorySlugs.map((cat) {
            final isSelected = _selectedCategory == cat;
            return _SelectChip(
              label:
                  '${getCategoryEmoji(cat)} ${getCategoryLabel(cat)}',
              selected: isSelected,
              onTap: () => setState(() => _selectedCategory = cat),
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecipientField() {
    return FAutocomplete(
      items: _recentRecipients,
      label: const Text('Recipient (optional)'),
      hint: 'Enter recipient name',
      control: FAutocompleteControl.managed(
        onChange: (val) => setState(() => _recipientText = val.text),
      ),
    );
  }

  Widget _buildDateSection(FThemeData theme) {
    final today = DateTime.now();
    final dateOptions = List.generate(4, (i) {
      final d = today.subtract(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    final selDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Date',
                style: theme.typography.sm
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Row(
              children: [
                Text('Recurring', style: theme.typography.sm),
                const SizedBox(width: 8),
                FSwitch(
                  value: _isRecurring,
                  onChange: (v) => setState(() => _isRecurring = v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...dateOptions.map((d) {
              return _SelectChip(
                label: _dateChipLabel(d),
                selected: selDay == d,
                onTap: () => setState(() => _selectedDate = d),
                theme: theme,
              );
            }),
            _SelectChip(
              label: 'Open Calendar',
              selected: false,
              onTap: _pickDate,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencySection(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        for (final freq in ['weekly', 'monthly', 'custom'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _frequency = freq),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  FRadio(
                    value: _frequency == freq,
                    onChange: (_) => setState(() => _frequency = freq),
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
    );
  }

  Widget _buildNotesField() {
    return FTextField(
      control: FTextFieldControl.managed(controller: _notesController),
      label: const Text('Notes (optional)'),
      hint: 'Add a note...',
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: FButton(
        onPress: _amount > 0 && !_isSaving ? _save : null,
        mainAxisSize: MainAxisSize.max,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save Expense'),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FThemeData theme;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colors.primary : theme.colors.muted,
          borderRadius: theme.style.borderRadius,
          border: Border.all(
            color: selected
                ? theme.colors.primary
                : theme.colors.border,
          ),
        ),
        child: Text(
          label,
          style: theme.typography.sm.copyWith(
            color: selected
                ? theme.colors.primaryForeground
                : theme.colors.foreground,
            fontWeight:
                selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
