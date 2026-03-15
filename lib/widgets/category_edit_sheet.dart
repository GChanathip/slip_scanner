import 'package:flutter/material.dart';
import '../models/custom_category.dart';

/// Bottom sheet for creating or editing a custom category.
///
/// NOTE: This is a placeholder implementation. Full UI will be implemented
/// as part of the SlipDetailScreen learning UX task.
class CategoryEditSheet extends StatefulWidget {
  final CustomCategory? category;

  const CategoryEditSheet._({super.key, this.category});

  /// Open in create mode (empty form).
  factory CategoryEditSheet.create() => const CategoryEditSheet._();

  /// Open in edit mode prefilled with [category].
  factory CategoryEditSheet.edit(CustomCategory? category) =>
      CategoryEditSheet._(category: category);

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: call CategoryService.create / update
                  Navigator.of(context).maybePop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
