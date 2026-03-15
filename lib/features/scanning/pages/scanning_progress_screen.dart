import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:avers/features/scanning/providers/scanning_provider.dart';
import 'package:avers/features/scanning/providers/scanning_state.dart';

@RoutePage()
class ScanningProgressScreen extends ConsumerStatefulWidget {
  const ScanningProgressScreen({super.key});

  @override
  ConsumerState<ScanningProgressScreen> createState() => _ScanningProgressScreenState();
}

class _ScanningProgressScreenState extends ConsumerState<ScanningProgressScreen> {
  @override
  void initState() {
    super.initState();

    // Listen for completion - fires immediately if already complete, then on changes
    // This replaces the hacky _hasShownCompletionDialog flag pattern
    ref.listenManual(scanningProvider.select((state) => state.isComplete), (previous, isComplete) {
      if (isComplete) {
        // Schedule dialog for after the current frame to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final state = ref.read(scanningProvider);
            _showCompletionDialog(state.processedPhotos, state.slipsFound, state.iCloudSkipped);
          }
        });
      }
    }, fireImmediately: true);

    // Start scanning - provider handles all state checks
    Future.microtask(() {
      ref.read(scanningProvider.notifier).startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final scanningState = ref.watch(scanningProvider);

    if (scanningState.error != null) {
      return _buildErrorView(theme, scanningState.error!);
    }

    return _buildProgressView(theme, scanningState);
  }

  Widget _buildErrorView(FThemeData theme, String error) {
    return FScaffold(
      header: const FHeader(title: Text('Scanning Error')),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FIcons.circleAlert, size: 64, color: theme.colors.destructive),
              const SizedBox(height: 16),
              Text('Scanning Failed', style: theme.typography.xl3),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: () {
                  ref.read(scanningProvider.notifier).reset();
                  context.router.maybePop(false);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView(FThemeData theme, ScanningState scanningState) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Scanning Photos'),
        prefixes: [
          FHeaderAction.x(onPress: scanningState.isScanning ? _cancelScanning : () => context.router.maybePop(false)),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressCircle(theme, scanningState),
              const SizedBox(height: 32),
              Text(
                scanningState.isScanning ? 'Scanning your photos for payment slips...' : 'Processing results...',
                style: theme.typography.lg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildStatsCard(theme, scanningState),
              const SizedBox(height: 32),
              if (scanningState.isScanning)
                FButton(variant: FButtonVariant.outline, onPress: _cancelScanning, child: const Text('Cancel Scanning')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(FThemeData theme, ScanningState scanningState) {
    final progress = scanningState.progress;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: scanningState.isScanning ? progress : 1.0,
            strokeWidth: 8,
            backgroundColor: theme.colors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primary),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(progress * 100).toInt()}%', style: theme.typography.xl3.copyWith(fontWeight: FontWeight.bold)),
                if (scanningState.isScanning) Text('Scanning', style: theme.typography.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(FThemeData theme, ScanningState scanningState) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Photos Processed:'),
                Text(
                  '${scanningState.processedPhotos} / ${scanningState.totalPhotos}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Slips Found:'),
                Text(
                  '${scanningState.slipsFound}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colors.primary),
                ),
              ],
            ),
            if (scanningState.iCloudSkipped > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('iCloud Photos Skipped:'),
                  Text(
                    '${scanningState.iCloudSkipped}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(int processed, int found, int iCloudSkipped) {
    final skippedNote = iCloudSkipped > 0
        ? ' $iCloudSkipped photo${iCloudSkipped == 1 ? ' was' : 's were'} skipped because they are stored in iCloud and not downloaded to this device.'
        : '';
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        title: const Text('Scanning Complete'),
        body: Text('Processed $processed photos and found $found payment slips.$skippedNote'),
        direction: Axis.vertical,
        actions: [
          FButton(
            onPress: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              ref.read(scanningProvider.notifier).reset();
              context.router.maybePop(true); // Return to home with refresh signal
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelScanning() async {
    try {
      await ref.read(scanningProvider.notifier).cancelScanning();
      if (mounted) {
        context.router.maybePop(false);
      }
    } catch (e) {
      if (mounted) {
        showFToast(context: context, title: const Text('Error'), description: Text('Failed to cancel: $e'));
      }
    }
  }
}
