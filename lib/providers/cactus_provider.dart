import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cactus_service.dart';
import 'cactus_state.dart';

part 'cactus_provider.g.dart';

const _selectedModelKey = 'selected_cactus_model';

@Riverpod(keepAlive: true)
class Cactus extends _$Cactus {
  @override
  CactusState build() {
    // Load saved model preference on startup
    _loadSavedModelPreference();
    return const CactusState();
  }

  Future<void> _loadSavedModelPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModel = prefs.getString(_selectedModelKey);
      if (savedModel != null) {
        state = state.copyWith(selectedModel: savedModel);
      }
    } catch (e) {
      // Ignore errors loading preferences
    }
  }

  Future<void> _saveModelPreference(String model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedModelKey, model);
    } catch (e) {
      // Ignore errors saving preferences
    }
  }

  /// Download and initialize a model
  Future<void> downloadAndInitialize(String modelSlug) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isDownloading: true,
      error: null,
      downloadProgress: 0.0,
      downloadStatus: 'Starting download...',
    );

    try {
      // Check if already downloaded
      final isDownloaded = await CactusService.instance.isModelDownloaded(modelSlug);

      if (!isDownloaded) {
        await CactusService.instance.downloadModel(
          modelSlug: modelSlug,
          onProgress: (progress, status) {
            state = state.copyWith(
              downloadProgress: progress ?? 0.0,
              downloadStatus: status,
            );
          },
        );
      }

      state = state.copyWith(
        isDownloading: false,
        isInitializing: true,
        downloadStatus: 'Initializing model...',
      );

      await CactusService.instance.initializeModel(model: modelSlug);

      await _saveModelPreference(modelSlug);

      state = state.copyWith(
        isInitializing: false,
        isModelLoaded: true,
        selectedModel: modelSlug,
        downloadStatus: 'Model ready',
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        isInitializing: false,
        error: e.toString(),
      );
    }
  }

  /// Unload the current model to free memory
  void unloadModel() {
    CactusService.instance.unload();
    state = state.copyWith(
      isModelLoaded: false,
      downloadStatus: 'Model unloaded',
    );
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if a specific model is downloaded
  Future<bool> isModelDownloaded(String modelSlug) async {
    return await CactusService.instance.isModelDownloaded(modelSlug);
  }
}
