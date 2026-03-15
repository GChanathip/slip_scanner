import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

Future<bool> showDeleteConfirmation(BuildContext context) async {
  final result = await showFDialog<bool>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      animation: animation,
      title: const Text('Delete Slip'),
      body: const Text('Are you sure you want to delete this payment slip?'),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
