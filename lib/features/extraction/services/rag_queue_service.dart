import 'dart:async';
import 'dart:collection';

import 'package:avers/core/database/database_service.dart';
import 'package:avers/core/models/payment_slip.dart';
import 'package:avers/features/ai/services/cactus_service.dart';
import 'package:avers/features/extraction/services/extraction_service.dart';
import 'package:flutter/foundation.dart';

/// Task containing slip and extraction result for RAG indexing
class _RAGTask {
  final PaymentSlip slip;
  final ExtractionResult result;
  _RAGTask({required this.slip, required this.result});
}

/// Background queue for RAG indexing (lower priority than extraction).
/// Processes embeddings when LLM is idle, doesn't block extraction queue.
class RAGQueueService {
  static final RAGQueueService _instance = RAGQueueService._();
  static RAGQueueService get instance => _instance;
  RAGQueueService._();

  final Queue<_RAGTask> _queue = Queue();
  Completer<void>? _workAvailable;

  /// Add a slip to the RAG indexing queue (fire-and-forget)
  void enqueue(PaymentSlip slip, ExtractionResult result) {
    _queue.add(_RAGTask(slip: slip, result: result));
    // Signal that work is available
    _workAvailable?.complete();
    _workAvailable = null;
  }

  /// Process one item from queue. Returns true if an item was processed.
  Future<bool> processOne() async {
    if (_queue.isEmpty) return false;

    final task = _queue.removeFirst();
    try {
      await _indexInRAG(task.slip, task.result);
      debugPrint('📚 RAG indexed slip ${task.slip.id}');
    } catch (e) {
      // Log but don't fail - RAG is optional enhancement
      debugPrint('📚 RAG indexing error for slip ${task.slip.id}: $e');
    }
    return true;
  }

  /// Wait until there's work or timeout
  Future<bool> waitForWork(Duration timeout) async {
    if (_queue.isNotEmpty) return true;

    _workAvailable = Completer<void>();
    await Future.any([
      _workAvailable!.future,
      Future.delayed(timeout),
    ]);
    return _queue.isNotEmpty;
  }

  /// Number of items pending in RAG queue
  int get pendingCount => _queue.length;

  /// Check if queue has pending items
  bool get hasPending => _queue.isNotEmpty;

  /// Index a slip in RAG for semantic search
  Future<void> _indexInRAG(PaymentSlip slip, ExtractionResult result) async {
    // Create rich document for RAG indexing
    final content = '''
Payment of ${slip.amount} baht on ${slip.date.toIso8601String().split('T')[0]}.
${result.recipientName != null ? 'To: ${result.recipientName}' : ''}
${result.notes != null ? 'Notes: ${result.notes}' : ''}
${result.category != null ? 'Category: ${result.category}' : ''}
Original text: ${slip.extractedText.substring(0, slip.extractedText.length > 500 ? 500 : slip.extractedText.length)}
''';

    await CactusService.instance.storeInRAG(
      id: slip.id.toString(),
      content: content,
    );

    await DatabaseService.updateRAGIndexed(slip.id!, true);
  }

  /// Clear the queue (for testing/reset)
  void clear() {
    _queue.clear();
  }
}
