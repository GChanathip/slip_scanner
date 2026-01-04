import 'dart:async';

/// Singleton for extraction event notifications.
/// Provides event-driven communication between DB inserts and extraction queue.
class ExtractionNotifier {
  static final ExtractionNotifier _instance = ExtractionNotifier._();
  static ExtractionNotifier get instance => _instance;
  ExtractionNotifier._();

  final _newSlipsController = StreamController<List<int>>.broadcast();
  final _extractionCompleteController = StreamController<int>.broadcast();

  /// Stream of new slip IDs that need extraction
  Stream<List<int>> get onNewSlips => _newSlipsController.stream;

  /// Stream of completed extraction IDs
  Stream<int> get onExtractionComplete => _extractionCompleteController.stream;

  /// Notify that new slips have been inserted and need extraction
  void notifyNewSlips(List<int> slipIds) {
    if (slipIds.isNotEmpty) {
      _newSlipsController.add(slipIds);
    }
  }

  /// Notify that extraction completed for a slip
  void notifyExtractionComplete(int slipId) {
    _extractionCompleteController.add(slipId);
  }

  void dispose() {
    _newSlipsController.close();
    _extractionCompleteController.close();
  }
}
