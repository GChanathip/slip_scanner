import 'dart:async';

import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.example.slip_scanner/vision');
  static const MethodChannel _progressChannel = MethodChannel('com.example.slip_scanner/progress');

  static StreamController<Map<String, dynamic>>? _progressController;
  static StreamController<Map<String, dynamic>>? _partialResultsController;

  /// Start scanning - returns immediately, does NOT wait for completion
  /// Listen to getProgressStream() for updates and completion (isComplete: true)
  /// Pass [processedAssetIds] to skip already-scanned photos on iOS.
  static Future<void> startScanning({List<String> processedAssetIds = const []}) async {
    try {
      // Fire and forget - iOS returns immediately with "started" status
      await _channel.invokeMethod('scanAllPhotos', {
        'processedAssetIds': processedAssetIds,
      });
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
          // No throttling - pass through every update immediately
          _progressController?.add(progress);
        } else if (call.method == 'onPartialResults') {
          final partialData = Map<String, dynamic>.from(call.arguments);
          _partialResultsController?.add(partialData);
        }
      });
    }

    return _progressController!.stream;
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
    _progressController?.close();
    _progressController = null;
    _partialResultsController?.close();
    _partialResultsController = null;
  }

  /// Process raw image data through OCR (macOS server path).
  /// Returns structured slip result or null if not a payment slip.
  static Future<Map<String, dynamic>?> processImageData(Uint8List imageData) async {
    try {
      final result = await _channel.invokeMethod('processImageData', {
        'imageData': imageData,
      });
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to process image data: ${e.message}');
    }
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

  /// Load image bytes from a PHAsset local identifier (batch-scanned slips).
  /// Returns null if the asset is not found or cannot be loaded.
  static Future<Uint8List?> loadImageFromAsset(String assetId) async {
    try {
      final result = await _channel.invokeMethod('loadImageFromAsset', {
        'assetId': assetId,
      });
      if (result is Uint8List) return result;
      if (result is List) return Uint8List.fromList(result.cast<int>());
      return null;
    } on PlatformException {
      return null;
    }
  }
}
