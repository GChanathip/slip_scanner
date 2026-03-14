import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../server/server_service.dart';
import '../services/config_service.dart';

@RoutePage()
class ServerDashboardScreen extends StatefulWidget {
  const ServerDashboardScreen({super.key});

  @override
  State<ServerDashboardScreen> createState() => _ServerDashboardScreenState();
}

class _ServerDashboardScreenState extends State<ServerDashboardScreen> {
  final _serverService = ServerService();
  final _tokenController = TextEditingController();
  final _secretController = TextEditingController();
  final _portController = TextEditingController(text: '8080');

  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tokenController.dispose();
    _secretController.dispose();
    _portController.dispose();
    _serverService.stop();
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

  Future<void> _toggleServer() async {
    setState(() => _isLoading = true);
    try {
      if (_serverService.isRunning) {
        await _serverService.stop();
      } else {
        await _saveConfig();
        await _serverService.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Slip Scanner Server'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            const SizedBox(height: 16),
            _buildServerControls(),
            const SizedBox(height: 24),
            _buildLineConfig(),
            const SizedBox(height: 24),
            _buildSetupInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
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
            _serverService.isRunning ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: _serverService.isRunning ? Colors.green : theme.colors.border,
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

  Widget _buildServerControls() {
    return FCard(
      title: const Text('Server'),
      subtitle: const Text('Control the HTTP server for LINE webhook'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: FTextField(
                control: FTextFieldControl.managed(controller: _portController),
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
                    child: const Text('Start'),
                  ),
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
              control: FTextFieldControl.managed(controller: _tokenController),
              hint: 'Channel Access Token',
              enabled: !_serverService.isRunning,
            ),
            const SizedBox(height: 12),
            FTextField(
              control: FTextFieldControl.managed(controller: _secretController),
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
