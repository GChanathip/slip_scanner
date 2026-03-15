import 'package:auto_route/auto_route.dart';
import 'package:cactus/cactus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:avers/features/ai/providers/cactus_state.dart';
import 'package:avers/features/ai/providers/cactus_provider.dart';
import 'package:avers/features/extraction/providers/extraction_provider.dart';
import 'package:avers/router/app_router.dart';
import 'package:avers/features/ai/services/cactus_service.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<CactusModel>? _availableModels;
  bool _isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final models = await CactusService.instance.getAvailableModels();
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isLoadingModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cactusState = ref.watch(cactusProvider);
    final extractionState = ref.watch(extractionQueueProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('AI Settings'),
        prefixes: [FHeaderAction.back(onPress: () => context.router.maybePop())],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model Status Card
          FCard(
            title: const Text('AI Model'),
            subtitle: Text(
              cactusState.isModelLoaded ? 'Model loaded and ready' : 'Select a model to enable AI features',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (cactusState.isModelLoaded) ...[
                  Row(
                    children: [
                      Icon(FIcons.check, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('Current: ${cactusState.selectedModel}', style: theme.typography.base),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () {
                      ref.read(cactusProvider.notifier).unloadModel();
                      ref.read(extractionQueueProvider.notifier).stopBackgroundProcessing();
                    },
                    child: const Text('Unload Model'),
                  ),
                ] else if (cactusState.isLoading) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cactusState.downloadStatus, style: theme.typography.sm),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: cactusState.isDownloading ? cactusState.downloadProgress : null),
                    ],
                  ),
                ] else if (cactusState.error != null) ...[
                  FAlert(
                    variant: FAlertVariant.destructive,
                    title: const Text('Error'),
                    subtitle: Text(cactusState.error!),
                  ),
                  const SizedBox(height: 12),
                  FButton(onPress: () => ref.read(cactusProvider.notifier).clearError(), child: const Text('Dismiss')),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Available Models Card
          FCard(
            title: const Text('Available Models'),
            subtitle: const Text('Choose a model to download and use'),
            child: Column(
              children: [
                const SizedBox(height: 12),
                if (_isLoadingModels)
                  const Center(child: CircularProgressIndicator())
                else if (_availableModels == null || _availableModels!.isEmpty)
                  const Text('Failed to load models')
                else
                  ..._availableModels!.map((model) => _buildModelTile(model, cactusState)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Categories Card
          FCard(
            title: const Text('Categories'),
            subtitle: const Text('Manage custom expense categories.'),
            child: Column(
              children: [
                const SizedBox(height: 12),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => context.router.push(const CategoryManagementRoute()),
                  prefix: const Icon(FIcons.tag),
                  child: const Text('Manage Categories'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Background Processing Card
          FCard(
            title: const Text('Background Processing'),
            subtitle: const Text('LLM extraction runs in background after scanning'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildStatRow('Pending', extractionState.pendingCount.toString()),
                _buildStatRow('Processed', extractionState.processedCount.toString()),
                _buildStatRow('Failed', extractionState.failedCount.toString()),
                _buildStatRow('Status', extractionState.isProcessing ? 'Running' : 'Stopped'),
                if (extractionState.failedCount > 0) ...[
                  const SizedBox(height: 12),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () {
                      ref.read(extractionQueueProvider.notifier).retryFailed();
                    },
                    child: const Text('Retry Failed'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile(CactusModel model, CactusState cactusState) {
    final theme = context.theme;
    final isSelected = cactusState.selectedModel == model.slug;
    final isLoading = cactusState.isLoading && cactusState.selectedModel == model.slug;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        model.name,
                        style: theme.typography.base.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (model.isDownloaded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Downloaded', style: theme.typography.sm.copyWith(color: Colors.green)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.sizeMb} MB${model.supportsToolCalling ? ' • Tools' : ''}${model.supportsVision ? ' • Vision' : ''}',
                  style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          if (isSelected && cactusState.isModelLoaded)
            Icon(FIcons.check, color: Colors.green)
          else if (isLoading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            FButton(
              onPress: cactusState.isLoading
                  ? null
                  : () async {
                      await ref.read(cactusProvider.notifier).downloadAndInitialize(model.slug);
                      // Start background extraction after model loads
                      if (ref.read(cactusProvider).isModelLoaded) {
                        ref.read(extractionQueueProvider.notifier).startBackgroundProcessing();
                      }
                    },
              child: Text(model.isDownloaded ? 'Load' : 'Download'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.typography.sm),
          Text(value, style: theme.typography.base.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
