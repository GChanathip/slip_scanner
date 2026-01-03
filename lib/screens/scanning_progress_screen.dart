import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/scanning_provider.dart';
import '../providers/scanning_state.dart';

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
            _showCompletionDialog(state.processedPhotos, state.slipsFound);
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
    final theme = ShadTheme.of(context);
    final scanningState = ref.watch(scanningProvider);

    if (scanningState.error != null) {
      return _buildErrorView(theme, scanningState.error!);
    }

    return _buildProgressView(theme, scanningState);
  }

  Widget _buildErrorView(ShadThemeData theme, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Error'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.foreground,
      ),
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, size: 64, color: theme.colorScheme.destructive),
              const SizedBox(height: 16),
              Text('Scanning Failed', style: theme.textTheme.h2),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: theme.textTheme.muted),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: () {
                  ref.read(scanningProvider.notifier).reset();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView(ShadThemeData theme, ScanningState scanningState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Photos'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.foreground,
        leading: ShadIconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: scanningState.isScanning ? _cancelScanning : () => Navigator.of(context).pop(false),
        ),
      ),
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressCircle(theme, scanningState),
              const SizedBox(height: 32),
              Text(
                scanningState.isScanning ? 'Scanning your photos for payment slips...' : 'Processing results...',
                style: theme.textTheme.large,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildStatsCard(theme, scanningState),
              const SizedBox(height: 32),
              if (scanningState.isScanning)
                ShadButton.outline(onPressed: _cancelScanning, child: const Text('Cancel Scanning')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(ShadThemeData theme, ScanningState scanningState) {
    final progress = scanningState.progress;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: scanningState.isScanning ? progress : 1.0,
            strokeWidth: 8,
            backgroundColor: theme.colorScheme.muted,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(progress * 100).toInt()}%', style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.bold)),
                if (scanningState.isScanning) Text('Scanning', style: theme.textTheme.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ShadThemeData theme, ScanningState scanningState) {
    return ShadCard(
      width: double.infinity,
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(int processed, int found) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Scanning Complete'),
        description: Text('Processed $processed photos and found $found payment slips.'),
        actions: [
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              ref.read(scanningProvider.notifier).reset();
              Navigator.of(context).pop(true); // Return to home with refresh signal
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
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(ShadToast(title: const Text('Error'), description: Text('Failed to cancel: $e')));
      }
    }
  }
}
