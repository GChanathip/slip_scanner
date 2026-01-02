import 'package:flutter/services.dart';
import 'dart:async';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.example.slip_scanner/vision');
  static const MethodChannel _progressChannel = MethodChannel('com.example.slip_scanner/progress');

  static StreamController<Map<String, dynamic>>? _progressController;
  static StreamController<Map<String, dynamic>>? _partialResultsController;

  // Throttling state for progress updates
  static DateTime? _lastProgressUpdate;
  static Map<String, dynamic>? _pendingProgress;
  static Timer? _throttleTimer;
  static const _throttleInterval = Duration(milliseconds: 500);

  /// Start scanning - returns immediately, does NOT wait for completion
  /// Listen to getProgressStream() for updates and completion (isComplete: true)
  static Future<void> startScanning() async {
    try {
      // Fire and forget - iOS returns immediately with "started" status
      await _channel.invokeMethod('scanAllPhotos');
    } on PlatformException catch (e) {
      throw Exception('Failed to start scanning: ${e.message}');
    }
  }

  @Deprecated('Use startScanning() instead - this blocks the UI thread on Flutter 3.35+')
  static Future<Map<String, dynamic>> scanAllPhotos() async {
    try {
      final result = await _channel.invokeMethod('scanAllPhotos');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to scan all photos: ${e.message}');
    }
  }

  static Future<bool> cancelScanning() async {
    try {
      final result = await _channel.invokeMethod('cancelScanning');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel scanning: ${e.message}');
    }
  }

  static Future<List<String>> getProcessedPhotoIds() async {
    try {
      final result = await _channel.invokeMethod('getProcessedPhotoIds');
      return List<String>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to get processed photo IDs: ${e.message}');
    }
  }

  static Stream<Map<String, dynamic>> getProgressStream() {
    if (_progressController == null) {
      _progressController = StreamController<Map<String, dynamic>>.broadcast();

      _progressChannel.setMethodCallHandler((call) async {
        if (call.method == 'onProgress') {
          final progress = Map<String, dynamic>.from(call.arguments);
          _throttledProgressUpdate(progress);
        } else if (call.method == 'onPartialResults') {
          final partialData = Map<String, dynamic>.from(call.arguments);
          _partialResultsController?.add(partialData);
        }
      });
    }

    return _progressController!.stream;
  }

  /// Throttles progress updates to max 2 per second to prevent UI rebuild storm
  static void _throttledProgressUpdate(Map<String, dynamic> progress) {
    final now = DateTime.now();
    final isComplete = progress['isComplete'] == true;

    // Always send immediately if complete (final update)
    if (isComplete) {
      _progressController?.add(progress);
      _throttleTimer?.cancel();
      _throttleTimer = null;
      _pendingProgress = null;
      return;
    }

    // Check if enough time has passed since last update
    if (_lastProgressUpdate == null ||
        now.difference(_lastProgressUpdate!) >= _throttleInterval) {
      _lastProgressUpdate = now;
      _progressController?.add(progress);
    } else {
      // Store pending update and schedule delivery
      _pendingProgress = progress;
      _throttleTimer?.cancel();
      _throttleTimer = Timer(_throttleInterval, () {
        if (_pendingProgress != null) {
          _progressController?.add(_pendingProgress!);
          _lastProgressUpdate = DateTime.now();
          _pendingProgress = null;
        }
      });
    }
  }

  static Stream<Map<String, dynamic>> getPartialResultsStream() {
    if (_partialResultsController == null) {
      _partialResultsController = StreamController<Map<String, dynamic>>.broadcast();

      // Ensure the progress channel handler is set up (it handles both progress and partial results)
      getProgressStream();
    }

    return _partialResultsController!.stream;
  }

  static void dispose() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _pendingProgress = null;
    _lastProgressUpdate = null;
    _progressController?.close();
    _progressController = null;
    _partialResultsController?.close();
    _partialResultsController = null;
  }

  static Future<Map<String, dynamic>> scanPaymentSlip(String imagePath) async {
    try {
      final result = await _channel.invokeMethod('scanPaymentSlip', {
        'imagePath': imagePath,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to scan payment slip: ${e.message}');
    }
  }

  static Future<bool> deleteSlipImage(String imagePath) async {
    try {
      final result = await _channel.invokeMethod('deleteSlipImage', {
        'imagePath': imagePath,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to delete slip image: ${e.message}');
    }
  }
}
