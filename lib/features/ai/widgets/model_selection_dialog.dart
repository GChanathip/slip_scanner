import 'package:cactus/cactus.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:avers/features/ai/services/cactus_service.dart';

/// Shows a dialog for the user to select an AI model.
/// Returns the selected model slug, or null if cancelled.
Future<String?> showModelSelectionDialog(BuildContext context) async {
  final models = await CactusService.instance.getAvailableModels();
  if (!context.mounted) return null;

  return showFDialog<String>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      animation: animation,
      direction: Axis.vertical,
      title: const Text('Select AI Model'),
      body: _ModelList(
        models: models,
        onSelected: (slug) => Navigator.pop(dialogContext, slug),
      ),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.pop(dialogContext, null),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _ModelList extends StatelessWidget {
  final List<CactusModel> models;
  final ValueChanged<String> onSelected;

  const _ModelList({required this.models, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: models.map((model) {
            final subtitleParts = <String>[
              '${model.sizeMb} MB',
              if (model.supportsToolCalling) 'Tools',
              if (model.supportsVision) 'Vision',
              if (model.isDownloaded) 'Downloaded',
            ];
            return FTile(
              title: Text(model.name),
              subtitle: Text(subtitleParts.join(' • ')),
              suffix: const Icon(FIcons.chevronRight, size: 16),
              onPress: () => onSelected(model.slug),
            );
          }).toList(),
        ),
      ),
    );
  }
}
