import 'package:cactus/cactus.dart';

/// Singleton service managing CactusLM and CactusRAG lifecycle.
/// Handles model download, initialization, and cleanup.
class CactusService {
  static CactusService? _instance;
  CactusLM? _lm;
  CactusRAG? _rag;
  String? _currentModel;
  bool _isModelLoaded = false;

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
    _rag = CactusRAG();
    await _rag!.initialize();
    _rag!.setEmbeddingGenerator((text) async {
      final result = await _lm!.generateEmbedding(text: text);
      return result.embeddings;
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
  Future<CactusCompletionResult> generateCompletion(List<ChatMessage> messages) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    return await _lm!.generateCompletion(messages: messages);
  }

  /// Stream completion (for chat UI)
  Future<CactusStreamedCompletionResult> generateCompletionStream(
    List<ChatMessage> messages,
  ) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    return await _lm!.generateCompletionStream(messages: messages);
  }

  /// Generate embedding for text
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isModelLoaded) throw Exception('Model not loaded');
    final result = await _lm!.generateEmbedding(text: text);
    return result.embeddings;
  }

  /// Store document in RAG
  Future<void> storeInRAG({
    required String id,
    required String content,
  }) async {
    if (_rag == null) throw Exception('RAG not initialized');
    await _rag!.storeDocument(
      fileName: 'slip_$id',
      filePath: '/slips/$id',
      content: content,
      fileSize: content.length,
    );
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
        final result = await _lm!.generateEmbedding(text: text);
        return result.embeddings;
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
