import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../providers/cactus_provider.dart';
import '../providers/cactus_state.dart';
import '../providers/extraction_provider.dart';
import '../providers/extraction_state.dart';
import '../server/server_service.dart';
import '../services/config_service.dart';

@RoutePage()
class ServerDashboardScreen extends ConsumerStatefulWidget {
  const ServerDashboardScreen({super.key});

  @override
  ConsumerState<ServerDashboardScreen> createState() =>
      _ServerDashboardScreenState();
}

class _ServerDashboardScreenState extends ConsumerState<ServerDashboardScreen> {
  final _serverService = ServerService.instance;
  final _tokenController = TextEditingController();
  final _secretController = TextEditingController();
  final _portController = TextEditingController(text: '8080');

  bool _isLoading = false;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _statusSubscription = _serverService.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _tokenController.dispose();
    _secretController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final token = await ConfigService.getLineChannelToken();
    final secret = await ConfigService.getLineChannelSecret();
    final port = await ConfigService.getServerPort();
    if (mounted) {
      setState(() {
        _tokenController.text = token ?? '';
        _secretController.text = secret ?? '';
        _portController.text = port.toString();
      });
    }
  }

  Future<void> _saveConfig() async {
    await ConfigService.setLineChannelToken(_tokenController.text.trim());
    await ConfigService.setLineChannelSecret(_secretController.text.trim());
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    await ConfigService.setServerPort(port);
  }

  int? _validatePort() {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) return null;
    return port;
  }

  /// Ensure CactusLM is loaded and extraction queue is running.
  Future<void> _ensureModelAndExtraction() async {
    final cactusState = ref.read(cactusProvider);
    if (!cactusState.isModelLoaded && !cactusState.isLoading) {
      await ref
          .read(cactusProvider.notifier)
          .downloadAndInitialize(cactusState.selectedModel);
    }
    if (ref.read(cactusProvider).isModelLoaded) {
      ref
          .read(extractionQueueProvider.notifier)
          .startBackgroundProcessing();
    }
  }

  Future<void> _toggleServer() async {
    if (!_serverService.isRunning) {
      final port = _validatePort();
      if (port == null) {
        if (mounted) {
          showFToast(
            context: context,
            title: const Text('Error'),
            description: const Text('Invalid port (must be 1-65535)'),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_serverService.isRunning) {
        await _serverService.stop();
      } else {
        await _saveConfig();
        // Initialize LLM and extraction queue before starting server
        await _ensureModelAndExtraction();
        await _serverService.start();
      }
    } catch (e,s) {
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: s);
      if (mounted) {
        showFToast(
          context: context,
          title: const Text('Error'),
          description: Text('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cactusState = ref.watch(cactusProvider);
    final extractionState = ref.watch(extractionQueueProvider);

    return FScaffold(
      header: FHeader(
        title: const Text('Slip Scanner Server'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(cactusState),
            const SizedBox(height: 16),
            _buildServerControls(cactusState),
            const SizedBox(height: 24),
            _buildModelStatus(cactusState, extractionState),
            const SizedBox(height: 24),
            _buildLineConfig(),
            const SizedBox(height: 24),
            _buildSetupInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(CactusState cactusState) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _serverService.isRunning
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colors.muted,
        borderRadius: theme.style.borderRadius,
      ),
      child: Row(
        children: [
          Icon(
            _serverService.isRunning
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 16,
            color:
                _serverService.isRunning ? Colors.green : theme.colors.border,
          ),
          const SizedBox(width: 8),
          Text(
            _serverService.isRunning
                ? 'Running on port ${_serverService.port}'
                : 'Server stopped',
            style: theme.typography.base,
          ),
        ],
      ),
    );
  }

  Widget _buildServerControls(CactusState cactusState) {
    final isStarting = _isLoading && !_serverService.isRunning;
    final buttonLabel = isStarting
        ? (cactusState.isLoading
            ? cactusState.downloadStatus
            : 'Starting...')
        : 'Start';

    return FCard(
      title: const Text('Server'),
      subtitle: const Text('Control the HTTP server for LINE webhook'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: FTextField(
                control:
                    FTextFieldControl.managed(controller: _portController),
                hint: 'Port',
                enabled: !_serverService.isRunning,
              ),
            ),
            const SizedBox(width: 16),
            _serverService.isRunning
                ? FButton(
                    onPress: _isLoading ? null : _toggleServer,
                    variant: FButtonVariant.destructive,
                    child: const Text('Stop'),
                  )
                : FButton(
                    onPress: _isLoading ? null : _toggleServer,
                    child: Text(buttonLabel),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatus(
      CactusState cactusState, ExtractionQueueState extractionState) {
    final theme = context.theme;

    String modelStatus;
    Color statusColor;
    if (cactusState.isModelLoaded) {
      modelStatus = 'Ready (${cactusState.selectedModel})';
      statusColor = Colors.green;
    } else if (cactusState.isLoading) {
      modelStatus = cactusState.downloadStatus;
      statusColor = Colors.orange;
    } else {
      modelStatus = 'Not loaded';
      statusColor = theme.colors.border;
    }

    return FCard(
      title: const Text('AI Engine'),
      subtitle: const Text('CactusLM model and extraction queue status'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Text('Model: $modelStatus', style: theme.typography.sm),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: extractionState.isProcessing
                      ? Colors.green
                      : theme.colors.border,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extraction: ${extractionState.isProcessing ? 'Running' : 'Idle'}'
                  ' (${extractionState.pendingCount} pending)',
                  style: theme.typography.sm,
                ),
              ],
            ),
            if (cactusState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${cactusState.error}',
                style: theme.typography.sm
                    .copyWith(color: theme.colors.destructive),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineConfig() {
    return FCard(
      title: const Text('LINE Bot Configuration'),
      subtitle: const Text('Enter your LINE Messaging API credentials'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            FTextField(
              control:
                  FTextFieldControl.managed(controller: _tokenController),
              hint: 'Channel Access Token',
              enabled: !_serverService.isRunning,
            ),
            const SizedBox(height: 12),
            FTextField(
              control:
                  FTextFieldControl.managed(controller: _secretController),
              hint: 'Channel Secret',
              enabled: !_serverService.isRunning,
            ),
            const SizedBox(height: 12),
            if (!_serverService.isRunning)
              FButton(
                onPress: _saveConfig,
                variant: FButtonVariant.outline,
                child: const Text('Save'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return FCard(
      title: const Text('Setup Instructions'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Create a LINE Bot in the LINE Developers Console\n'
              '2. Copy the Channel Access Token and Channel Secret above\n'
              '3. Start the server and note the port\n'
              '4. Expose your local server with Cloudflare Tunnel:',
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                'cloudflared tunnel --url http://localhost:${_portController.text}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.greenAccent,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '5. Set the tunnel URL as your LINE webhook URL:\n'
              '   https://your-tunnel.trycloudflare.com/webhook/line\n'
              '6. Send an image to your LINE bot!',
            ),
          ],
        ),
      ),
    );
  }
}
