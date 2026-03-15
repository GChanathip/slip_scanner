import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../services/config_service.dart';
import '../services/line_service.dart';
import 'routes/line_webhook.dart';

/// Manages the embedded shelf HTTP server lifecycle.
/// Singleton — the server outlives any individual screen.
class ServerService {
  ServerService._();
  static final instance = ServerService._();

  HttpServer? _server;
  LineService? _lineService;
  int _port = 8080;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get port => _port;
  LineService? get lineService => _lineService;

  /// Notifies listeners when the server status changes.
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// Start the shelf server.
  Future<void> start({int? port}) async {
    if (_isRunning) return;

    _port = port ?? await ConfigService.getServerPort();

    // Initialize LINE service if configured
    final token = await ConfigService.getLineChannelToken();
    final secret = await ConfigService.getLineChannelSecret();
    if (token != null && token.isNotEmpty && secret != null && secret.isNotEmpty) {
      _lineService = LineService(
        channelAccessToken: token,
        channelSecret: secret,
      );
    }

    final webhookHandler = LineWebhookHandler(lineService: _lineService);

    final router = Router()
      ..post('/webhook/line', webhookHandler.handle)
      ..get('/health', _healthHandler);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
    _isRunning = true;
    _statusController.add(true);
    debugPrint('Server started on port $_port');
  }

  /// Stop the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _lineService?.dispose();
    _lineService = null;
    _server = null;
    _isRunning = false;
    _statusController.add(false);
    debugPrint('Server stopped');
  }

  /// Restart with updated configuration.
  Future<void> restart() async {
    await stop();
    await start();
  }

  Response _healthHandler(Request request) {
    return Response.ok('OK');
  }
}
