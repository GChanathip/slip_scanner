import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

Future<bool> showDeleteConfirmation(BuildContext context) async {
  final result = await showFDialog<bool>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: (_) => style,
      animation: animation,
      direction: Axis.vertical,
      title: const Text('Delete Slip'),
      body: const Text('Are you sure you want to delete this payment slip?'),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FButton(
          style: FButtonStyle.destructive(),
          onPress: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
