import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avers/features/ai/providers/cactus_provider.dart';
import 'package:avers/features/extraction/providers/extraction_provider.dart';
import 'package:avers/features/ai/widgets/model_selection_dialog.dart';

/// Ensures the AI model is loaded, showing a selection dialog if the user
/// hasn't explicitly chosen a model yet.
///
/// Returns true if the model is loaded (or was loaded by this call).
/// Returns false if the user cancelled or an error occurred.
Future<bool> ensureModelLoaded(BuildContext context, WidgetRef ref) async {
  final cactusState = ref.read(cactusProvider);

  if (cactusState.isModelLoaded) return true;
  if (cactusState.isLoading) return false;

  String modelSlug = cactusState.selectedModel;

  if (!cactusState.hasExplicitlySelectedModel) {
    final selected = await showModelSelectionDialog(context);
    if (selected == null || !context.mounted) return false;
    modelSlug = selected;
    await ref.read(cactusProvider.notifier).selectModel(selected);
  }

  await ref.read(cactusProvider.notifier).downloadAndInitialize(modelSlug);

  if (ref.read(cactusProvider).isModelLoaded) {
    ref.read(extractionQueueProvider.notifier).startBackgroundProcessing();
    return true;
  }
  return false;
}
