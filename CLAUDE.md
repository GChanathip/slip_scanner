# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important

This project targets **iOS and macOS only** — ignore Android implementation.

## Project Overview

Flutter app (iOS + macOS) that scans payment slips using Apple Vision Framework OCR. Specializes in Thai banking slips (SCB, KBank Make/K Plus, Dime) with Thai language text recognition, Buddhist calendar conversion, and on-device LLM extraction via CactusLM. The macOS target embeds a shelf HTTP server for LINE bot integration — users send slip images via LINE chat and receive extracted payment data.

## Development Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on iOS simulator/device
flutter run -d macos         # Run macOS target (LINE bot server)
flutter build ios            # Build for iOS release
flutter test                 # Run all tests
flutter test test/foo_test.dart          # Run a single test file
flutter analyze              # Analyze code (includes riverpod_lint)
cd ios && pod install        # Install iOS dependencies
cd macos && pod install      # Install macOS dependencies
dart run build_runner build --delete-conflicting-outputs  # Generate code
dart run build_runner watch  # Watch mode for code generation
```

## Code Generation

After modifying files with `@riverpod`, `@freezed`, or `@RoutePage` annotations, run `dart run build_runner build --delete-conflicting-outputs`.

Generated files (do not edit manually):
- `*.g.dart` — Riverpod providers
- `*.freezed.dart` — Freezed immutable classes
- `lib/router/app_router.gr.dart` — AutoRoute routes

## Architecture Overview

### Platform-Conditional Routing

`main.dart` uses `Platform.isMacOS` to route the initial screen:
- **iOS**: Default home screen (photo scanning UI)
- **macOS**: `ServerDashboardScreen` (LINE bot server controls)

### Data Flow (iOS — Photo Library Scanning)

```
iOS Photos → scanAllPhotos(processedAssetIds) → DispatchQueue.global → OperationQueue (max 6)
  → skip already-processed assetIds → VisionKit OCR (accurate, th-TH + en-US)
  → RegexPatterns extraction → buildSlipResult() → PlatformService (streams)
  → ScanningProvider._insertBatch() [immediate, no accumulation]
  → DatabaseService.insertPaymentSlipsBatch()
  → ExtractionNotifier.notifyNewSlips() [event-driven]
  → ExtractionQueue._processingLoop()
  → ExtractionService.extractFromText() [LLM, async-locked]
  → DatabaseService.updateExtractedData()
  → RAGQueueService.enqueue() [fire-and-forget, lower priority]
```

### Data Flow (macOS — LINE Bot Server)

```
LINE webhook POST → verify HMAC-SHA256 signature → return 200 OK immediately
  → Image: LineService.getMessageContent() → SlipProcessorService.processLineImage()
      → PlatformService.processImageData() [platform channel]
      → Vision OCR (macOS) → convertSlipsInIsolate()
      → DatabaseService.insertPaymentSlipsBatch() → ExtractionNotifier (triggers LLM)
      → _formatSlipSummary() → LineService.replyMessage()
  → Text: ChatQueryService.processQuery() [guard: returns fallback if model not loaded]
      → RAG search → stats → buildSystemPrompt() → CactusService.generateCompletion()
      → LineService.replyMessage()
```

### UI (ForUI)

Design system: `forui` package (shadcn/ui-inspired). Components: `FButton`, `FCard`, `FAlert`, `FDialog`, `FToast`, `FScaffold`, `FHeader`. Theming via `FThemes.zinc` in `main.dart` (light/dark with auto-detection). See [docs/FORUI_GUIDE.md](docs/FORUI_GUIDE.md) for usage guide and [docs/FORUI_MIGRATION_SUMMARY.md](docs/FORUI_MIGRATION_SUMMARY.md) for migration notes.

### State Management (Riverpod + Freezed)

- `@riverpod` code generation for providers, `@freezed` for immutable state classes
- Key keepAlive providers: `ScanningProvider` (scan lifecycle), `ExtractionQueue` (LLM processing), `CactusProvider` (model management)

### Routing (AutoRoute)

Type-safe routing with `@RoutePage` annotations. Routes defined in `lib/router/app_router.dart`.

### Platform Channels

- `com.example.slip_scanner/vision` — OCR operations (scanAllPhotos, cancelScanning, scanPaymentSlip, deleteSlipImage, loadImageFromAsset, processImageData)
- `com.example.slip_scanner/progress` — Real-time callbacks (onProgress, onPartialResults) via `DispatchQueue.main.async`

### On-Device AI Pipeline (CactusLM + RAG)

**CactusService** (singleton): Manages CactusLM and CactusRAG lifecycle. Uses custom `_AsyncLock` (async mutex) to serialize all LLM operations — CactusLM is NOT thread-safe (causes EXC_BAD_ACCESS without locking). Streaming completions acquire lock at start, release when stream finishes.

**CactusLM initialization requirement**: The model must be explicitly downloaded and initialized via `CactusProvider.downloadAndInitialize()` before any LLM features work. On iOS this happens from `AnalysisScreen`/`SettingsScreen`/`ChatScreen`. On macOS, `ServerDashboardScreen._ensureModelAndExtraction()` initializes when the user starts the server. `ExtractionQueue.startBackgroundProcessing()` must also be called after model load — without it, slips sit in `pending` status and text queries return a fallback message.

**ExtractionService**: Extracts structured data (recipientName, notes, category) from OCR text via LLM. Fixed categories: food, transport, utilities, shopping, transfer, entertainment, health, education, other.

**ExtractionQueue** (provider): Event-driven background processing via `ExtractionNotifier` stream (no polling). Priority: extraction > RAG indexing. Uses ref-counted pause/resume (`_pauseCount`): `pauseExtraction()` increments, `resumeExtraction()` decrements, extraction resumes when count reaches zero. ChatScreen pauses on entry and resumes on exit to avoid LLM lock contention. Failed extractions increment `retryCount`; slips with `retryCount >= 3` are permanently skipped.

**RAGQueueService** (singleton): Fire-and-forget indexing — doesn't block extraction if RAG fails. Indexes rich documents (amount, date, recipient, notes, category, original text).

**ChatProvider**: Builds system prompt with expense stats + RAG context (top 5 relevant records), streams LLM completion. UI updates are batched every 100ms (not per-token) via `StringBuffer`. Delegates stats/prompt building to `ChatQueryService` (shared with LINE bot).

### macOS LINE Bot Server

**ServerService** (singleton via `ServerService.instance`): Embedded shelf HTTP server. Routes: `POST /webhook/line` (LINE events), `GET /health`. Lifecycle managed from `ServerDashboardScreen`; server outlives the screen (not stopped on dispose). Notifies UI of status changes via `statusStream`.

**LineService**: Pure Dart HTTP client for LINE Messaging API. Signature verification uses constant-time byte comparison (HMAC-SHA256). Handles reply messages (replyToken, ~30s validity) and push messages (userId, for async responses). Text messages truncated to 5000 chars (LINE API limit).

**ConfigService**: Hybrid storage — LINE credentials (channel token, channel secret) in `FlutterSecureStorage` (Keychain on macOS), server port in `SharedPreferences`.

**LineWebhookHandler**: Returns 200 OK immediately, processes events asynchronously via `unawaited()`. Tracks recent events (up to 50) in memory for dashboard display.

**SlipProcessorService**: Orchestrates image → OCR → DB → formatted reply for LINE images. Formats immediate OCR summary (amount, date, sender, recipient, ref) while LLM extraction runs in background.

### macOS Native Implementation

Under `macos/Runner/` (ported from iOS, using NSImage/CGImage instead of UIImage):

- **`AppDelegate.swift`** — Platform channel setup. Handles `processImageData` (raw bytes from LINE) and `scanPaymentSlip` (file path). Dispatches to `DispatchQueue.global()`.
- **`RegexPatterns.swift`** — Port of iOS regex patterns (shared logic, no UIKit dependency).
- **`OCRService.swift`** — Port of iOS OCR pipeline using Vision Framework with `CGImage`.
- **`SlipProcessor.swift`** — Bridges platform channel to OCR. Generates `line_<UUID>` asset IDs. No PHPhotoLibrary dependency.

**Note**: macOS `RegexPatterns.swift` and `OCRService.swift` are near-copies of the iOS versions. Changes to regex/OCR logic must be applied to both `ios/Runner/` and `macos/Runner/`.

### iOS Native Implementation

Under `ios/Runner/`:

- **`AppDelegate.swift`** — Platform channel setup and method routing only. Delegates all work to `PhotoScanner`.
- **`RegexPatterns.swift`** — 40+ pre-compiled `NSRegularExpression` patterns (compiled once at launch) for SCB, KBank (Make/K Plus), Dime formats. Includes amount, date, Thai month, Buddhist year, reference ID, sender/receiver name, account number, and date-time patterns.
- **`OCRService.swift`** — Vision Framework OCR (`recognizeText`), structured field extraction (`buildSlipResult`), `normalizeToISODate` for consistent date output, and Buddhist calendar conversion.
- **`PhotoScanner.swift`** — Bulk photo library scanning with `OperationQueue` (max `min(ProcessorCount, 6)` concurrent ops), single-image scanning, asset operations, `loadImageFromAsset` for PHAsset byte loading, iCloud skip detection, and progress throttling (every 50 images or 200ms).

**Critical (Flutter 3.35+)**: All blocking native work must use `DispatchQueue.global()`, NOT `Task{}` which inherits MainActor context on merged threads. `FlutterResult` must be called on the main thread.

### Database (SQLite, v5)

```
payment_slips:
  id, imagePath, assetId, amount, date, extractedText, createdAt,
  senderName, referenceId, senderAccount, receiverAccount, transactionTime,  -- OCR (v4)
  recipientName, notes, category,                                            -- LLM (v3)
  llmProcessingStatus ('pending'|'processing'|'completed'|'failed'),         -- LLM (v3)
  ragIndexed (0|1), updatedAt,                                               -- LLM (v3)
  retryCount (default 0)                                                     -- v5

Indexes: idx_assetId (dedup), idx_llm_status (queue), idx_referenceId (lookup)
```

Batch inserts use transactions with assetId deduplication. New inserts trigger `ExtractionNotifier.notifyNewSlips()`. Database init is guarded by a `Completer` to prevent concurrent initialization races.

## Key Conventions

- iOS returns empty strings `""` for missing optional fields (not nil) — Flutter side uses `nonEmpty()` helper to convert to null
- `convertSlipsInIsolate` must be a top-level function (required for `compute()` isolate compatibility)
- OCR receiver name pre-fills `recipientName`; LLM extraction overwrites if non-null
- Multi-bank regex patterns: arrays tried in priority order, first match wins
- KBank slips use positional extraction (no labels) — match index 0 = sender, index 1 = receiver
- Currency symbol is `฿` (Thai Baht), not `$`
- Shared helpers in `lib/utils/` (dialogs, formatters) and `lib/widgets/` (hero_card, slip_list_tile)
- Partial scan results are inserted to DB immediately per-batch (no state accumulation); `_pendingInserts` tracks in-flight futures so `_handleScanComplete` can `Future.wait` before finishing
- Already-processed assetIds are fetched from DB at scan start and passed to iOS to skip re-scanning
- macOS LINE images get `line_<UUID>` asset IDs (not PHAsset identifiers)

## Testing

### Dart Tests

```bash
flutter test                                        # Run all Dart tests
flutter test test/scanning_conversion_test.dart      # Run a specific test file
```

### iOS XCTests (OCR & Regex Extraction)

Requires an iOS Simulator. Tests the native OCR extraction pipeline (amounts, dates, names, accounts, reference IDs, Buddhist calendar conversion, `buildSlipResult` assembly) across all bank formats.

```bash
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RunnerTests/OCRExtractionTests \
  -only-testing:RunnerTests/BuddhistCalendarTests \
  -only-testing:RunnerTests/BuildSlipResultTests
```

### Adding a Regression Test

When a slip doesn't parse correctly:

1. Get the OCR text (from `extractedText` in the database or scanner log)
2. Add it as a new static constant in the appropriate bank fixture file in `ios/RunnerTests/Fixtures/`
3. Add expected values to the `Expected` struct
4. Write a test assertion in the relevant test file
5. Fix the regex/extraction logic, then run all tests to verify no regressions

## Linting

Uses `flutter_lints` with `riverpod_lint` plugin enabled (see `analysis_options.yaml`). Run `flutter analyze` to check.

## Requirements

- **Flutter SDK**: 3.38.x+ (Dart SDK ^3.10.4)
- **iOS Deployment Target**: 15.6+
- **macOS Deployment Target**: 13.0+
- **Xcode**: Latest for iOS/macOS development
