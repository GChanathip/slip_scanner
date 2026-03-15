import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:avers/features/server/services/config_service.dart';
import 'package:avers/features/server/services/line_service.dart';
import 'package:avers/features/server/routes/line_webhook.dart';

/// Manages the embedded shelf HTTP server lifecycle.
/// Singleton — the server outlives any individual screen.
class ServerService {
  ServerService._();
  static final instance = ServerService._();

  HttpServer? _server;
  LineService? _lineService;
  int _port = ConfigService.defaultPort;
  bool _isRunning = false;
  Completer<void>? _pendingOperation;

  bool get isRunning => _isRunning;
  int get port => _port;
  LineService? get lineService => _lineService;

  /// Notifies listeners when the server status changes.
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// Start the shelf server.
  Future<void> start({int? port}) async {
    if (_pendingOperation != null) {
      await _pendingOperation!.future;
    }
    if (_isRunning) return;

    _pendingOperation = Completer<void>();
    try {
      _port = port ?? await ConfigService.getServerPort();

      // Dispose any stale LINE service before creating a new one
      _lineService?.dispose();
      _lineService = null;

      // Initialize LINE service if configured
      final token = await ConfigService.getLineChannelToken();
      final secret = await ConfigService.getLineChannelSecret();
      if (token != null &&
          token.isNotEmpty &&
          secret != null &&
          secret.isNotEmpty) {
        _lineService = LineService(
          channelAccessToken: token,
          channelSecret: secret,
        );
      }

      final webhookHandler = LineWebhookHandler(lineService: _lineService);

      final router = Router()
        ..post('/webhook/line', webhookHandler.handle)
        ..get('/health', _healthHandler);

      final handler =
          const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      _isRunning = true;
      _statusController.add(true);
      debugPrint('Server started on port $_port');
    } finally {
      _pendingOperation!.complete();
      _pendingOperation = null;
    }
  }

  /// Stop the server.
  Future<void> stop() async {
    if (_pendingOperation != null) {
      await _pendingOperation!.future;
    }
    if (!_isRunning) return;

    _pendingOperation = Completer<void>();
    try {
      await _server?.close(force: true);
      _lineService?.dispose();
      _lineService = null;
      _server = null;
      _isRunning = false;
      _statusController.add(false);
      debugPrint('Server stopped');
    } finally {
      _pendingOperation!.complete();
      _pendingOperation = null;
    }
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
