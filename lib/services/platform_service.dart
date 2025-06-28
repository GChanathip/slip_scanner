import 'package:flutter/services.dart';
import 'dart:async';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.example.slip_scanner/vision');
  static const MethodChannel _progressChannel = MethodChannel('com.example.slip_scanner/progress');
  
  static StreamController<Map<String, dynamic>>? _progressController;

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
        print('📊 DEBUG Flutter: Received method call: ${call.method}');
        if (call.method == 'onProgress') {
          final progress = Map<String, dynamic>.from(call.arguments);
          print('📊 DEBUG Flutter: Progress update received: $progress');
          _progressController?.add(progress);
        }
      });
    }
    
    return _progressController!.stream;
  }

  static void dispose() {
    _progressController?.close();
    _progressController = null;
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