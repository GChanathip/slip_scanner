import 'dart:async';
import 'package:cactus/models/rag.dart';
import 'package:cactus/models/types.dart';
import 'package:cactus/services/lm.dart';
import 'package:cactus/services/rag.dart';
import 'package:flutter/foundation.dart';

/// Singleton service managing CactusLM and CactusRAG lifecycle.
/// Handles model download, initialization, and cleanup.
///
/// IMPORTANT: CactusLM is NOT thread-safe. All LLM operations must be
/// serialized using the _operationLock to prevent concurrent access
/// which causes EXC_BAD_ACCESS crashes in the native layer.
class CactusService {
  static CactusService? _instance;
  CactusLM? _lm;
  CactusRAG? _rag;
  String? _currentModel;
  bool _isModelLoaded = false;

  /// Lock to serialize all LLM operations (completions, embeddings)
  /// This prevents concurrent access to the native model which is not thread-safe
  final _operationLock = _AsyncLock();

  static CactusService get instance => _instance ??= CactusService._();
  CactusService._();

  bool get isLoaded => _isModelLoaded;
  String? get currentModel => _currentModel;
  CactusLM? get lm => _lm;
  CactusRAG? get rag => _rag;

  /// Download model with progress callback
  Future<void> downloadModel({
    required String modelSlug,
    required void Function(double? progress, String status) onProgress,
  }) async {
    _lm ??= CactusLM();
    await _lm!.downloadModel(
      model: modelSlug,
      downloadProcessCallback: (progress, status, isError) {
        if (!isError) onProgress(progress, status);
      },
    );
  }

  /// Initialize model (call after download)
  Future<void> initializeModel({String model = 'qwen3-0.6'}) async {
    _lm ??= CactusLM();
    await _lm!.initializeModel(params: CactusInitParams(model: model));
    _currentModel = model;
    _isModelLoaded = true;

    // Initialize RAG with embedding generator
    // IMPORTANT: Use the locked generateEmbedding method, not direct _lm! access
    _rag = CactusRAG();
    await _rag!.initialize();
    _rag!.setEmbeddingGenerator((text) async {
      // This goes through the lock to prevent concurrent native access
      return await generateEmbedding(text);
    });
    _rag!.setChunking(chunkSize: 512, chunkOverlap: 64);
  }

  /// Unload to free memory (e.g., when app goes to background)
  void unload() {
    _lm?.unload();
    _isModelLoaded = false;
    _currentModel = null;
  }

  /// Get available models
  Future<List<CactusModel>> getAvailableModels() async {
    _lm ??= CactusLM();
    return await _lm!.getModels();
  }

  /// Generate completion (for chat)
  /// Serialized via lock to prevent concurrent native access
  Future<CactusCompletionResult> generateCompletion(List<ChatMessage> messages) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    return await _operationLock.synchronized(() async {
      debugPrint('🔒 Acquiring lock for generateCompletion');
      final result = await _lm!.generateCompletion(messages: messages);
      debugPrint('🔓 Released lock for generateCompletion');
      return result;
    });
  }

  /// Stream completion (for chat UI)
  /// Note: We acquire lock at start but streaming happens async
  /// Caller must ensure no other LLM operations during stream consumption
  Future<CactusStreamedCompletionResult> generateCompletionStream(List<ChatMessage> messages) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    // For streaming, we need to hold the lock during the entire stream
    // We'll acquire it here and release when the stream is done
    await _operationLock.acquire();
    debugPrint('🔒 Acquired lock for generateCompletionStream');
    try {
      final streamResult = await _lm!.generateCompletionStream(messages: messages);
      // Wrap the stream to release lock when done
      final wrappedStream = streamResult.stream.transform(
        StreamTransformer<String, String>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleDone: (sink) {
            debugPrint('🔓 Releasing lock after stream done');
            _operationLock.release();
            sink.close();
          },
          handleError: (error, stackTrace, sink) {
            debugPrint('🔓 Releasing lock after stream error');
            _operationLock.release();
            sink.addError(error, stackTrace);
          },
        ),
      );
      return CactusStreamedCompletionResult(stream: wrappedStream, result: streamResult.result);
    } catch (e) {
      debugPrint('🔓 Releasing lock after stream setup error');
      _operationLock.release();
      rethrow;
    }
  }

  /// Generate embedding for text
  /// Serialized via lock to prevent concurrent native access
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    return await _operationLock.synchronized(() async {
      debugPrint(
        '🔒 Acquiring lock for generateEmbedding: ${text.substring(0, text.length > 30 ? 30 : text.length)}...',
      );
      final result = await _lm!.generateEmbedding(text: text);
      debugPrint('🔓 Released lock for generateEmbedding');
      return result.embeddings;
    });
  }

  /// Store document in RAG
  Future<void> storeInRAG({required String id, required String content}) async {
    if (_rag == null) throw Exception('RAG not initialized');
    await _rag!.storeDocument(fileName: 'slip_$id', filePath: '/slips/$id', content: content, fileSize: content.length);
  }

  /// Search RAG for similar content
  Future<List<ChunkSearchResult>> searchRAG(String query, {int limit = 10}) async {
    if (_rag == null) throw Exception('RAG not initialized');
    return await _rag!.search(text: query, limit: limit);
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelSlug) async {
    final models = await getAvailableModels();
    final model = models.where((m) => m.slug == modelSlug).firstOrNull;
    return model?.isDownloaded ?? false;
  }

  /// Reset RAG database (for debugging)
  Future<void> resetRAG() async {
    if (_rag != null) {
      await _rag!.close();
      _rag = CactusRAG();
      await _rag!.initialize();
      _rag!.setEmbeddingGenerator((text) async {
        // This goes through the lock to prevent concurrent native access
        return await generateEmbedding(text);
      });
      _rag!.setChunking(chunkSize: 512, chunkOverlap: 64);
    }
  }

  /// Get RAG stats
  Future<DatabaseStats?> getRAGStats() async {
    if (_rag == null) return null;
    return await _rag!.getStats();
  }
}

/// Simple async mutex lock to serialize async operations.
/// Used to prevent concurrent access to non-thread-safe native code.
class _AsyncLock {
  Completer<void>? _completer;

  /// Returns true if the lock is currently held
  bool get isLocked => _completer != null;

  /// Acquire the lock. If already held, wait until released.
  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  /// Release the lock
  void release() {
    final completer = _completer;
    _completer = null;
    completer?.complete();
  }

  /// Execute a function while holding the lock
  Future<T> synchronized<T>(Future<T> Function() fn) async {
    await acquire();
    try {
      return await fn();
    } finally {
      release();
    }
  }
}
