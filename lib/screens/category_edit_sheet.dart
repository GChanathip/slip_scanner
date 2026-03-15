import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/category_registry.dart';
import '../models/custom_category.dart';
import '../providers/category_provider.dart';

/// Shows the category edit sheet. Returns the saved category name, or null if cancelled.
Future<String?> showCategoryEditSheet(
  BuildContext context, {
  CustomCategory? existing,
}) {
  return showFSheet<String>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: null,
    builder: (context) => CategoryEditSheet(existing: existing),
  );
}

class CategoryEditSheet extends ConsumerStatefulWidget {
  final CustomCategory? existing;

  const CategoryEditSheet({super.key, this.existing});

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? 'utensils';
    _selectedColor = widget.existing?.color ?? 'orange';
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
    setState(() {});
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter a name');
      return;
    }

    // Duplicate check
    final allNames = await ref.read(allCategoryNamesProvider.future);
    final existingName = widget.existing?.name.toLowerCase();
    final isDuplicate = allNames.any(
      (n) => n.toLowerCase() == name.toLowerCase() && n.toLowerCase() != existingName,
    );
    if (isDuplicate) {
      setState(() => _errorText = 'A category with this name already exists.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(categoryMutationsProvider.notifier).saveCategory(
            id: widget.existing?.id,
            name: name,
            icon: _selectedIcon,
            color: _selectedColor,
          );
      if (mounted) {
        Navigator.pop(context, name);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = "Couldn't save. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final iconKeys = kCategoryIconSet.keys.toList();
    final colorKeys = kCategoryColorPalette.keys.toList();
    final name = _nameController.text.trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              _isEditMode ? 'Edit Category' : 'New Category',
              style: theme.typography.xl2.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Name field
            FTextField(
              control: FTextFieldControl.managed(controller: _nameController),
              label: const Text('Name'),
              hint: 'Category name',
              maxLength: 30,
              autofocus: !_isEditMode,
              enabled: !_isSaving,
              error: _errorText != null ? Text(_errorText!) : null,
            ),
            const SizedBox(height: 20),

            // Icon section
            Text('Icon', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final key in iconKeys) _buildIconButton(key, theme),
              ],
            ),
            const SizedBox(height: 20),

            // Color section
            Text('Color', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final key in colorKeys) _buildColorSwatch(key),
              ],
            ),
            const SizedBox(height: 24),

            // Preview
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    kCategoryIconSet[_selectedIcon] ?? FIcons.circle,
                    color: colorFromKey(_selectedColor),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name.isEmpty ? 'Category name' : name,
                    style: theme.typography.base.copyWith(
                      color: name.isEmpty ? theme.colors.mutedForeground : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FButton(
              onPress: _canSave ? _save : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: FCircularProgress(),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 8),

            // Cancel button
            FButton(
              variant: FButtonVariant.ghost,
              onPress: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(String key, FThemeData theme) {
    final isSelected = _selectedIcon == key;
    final iconData = kCategoryIconSet[key] ?? FIcons.circle;

    return GestureDetector(
      onTap: _isSaving
          ? null
          : () => setState(() => _selectedIcon = key),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colors.primary.withValues(alpha: 0.1)
              : theme.colors.secondary,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colors.primary, width: 2)
              : null,
        ),
        child: Icon(
          iconData,
          color: isSelected ? theme.colors.primary : theme.colors.foreground,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String key) {
    final isSelected = _selectedColor == key;
    final color = colorFromKey(key);

    return GestureDetector(
      onTap: _isSaving
          ? null
          : () => setState(() => _selectedColor = key),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: isSelected
            ? const Icon(FIcons.check, color: Color(0xFFFFFFFF), size: 16)
            : null,
      ),
    );
  }
}
