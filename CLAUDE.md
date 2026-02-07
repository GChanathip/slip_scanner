# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important

This project focuses on **iOS only** — ignore Android implementation.

## Project Overview

Flutter iOS app that scans payment slips from device photos using Apple Vision Framework OCR. Specializes in Thai banking slips (SCB, KBank Make/K Plus, Dime) with Thai language text recognition, Buddhist calendar conversion, and on-device LLM extraction via CactusLM.

## Development Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on iOS simulator/device
flutter build ios            # Build for iOS release
flutter test                 # Run tests
flutter analyze              # Analyze code (includes linting)
cd ios && pod install        # Install iOS dependencies
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

### Data Flow

```
iOS Photos → scanAllPhotos() → DispatchQueue.global → OperationQueue (max 6)
  → VisionKit OCR (accurate, th-TH + en-US) → RegexPatterns extraction
  → buildSlipResult() → PlatformService (streams) → ScanningProvider
  → DatabaseService.insertPaymentSlipsBatch()
  → ExtractionNotifier.notifyNewSlips() [event-driven]
  → ExtractionQueue._processingLoop()
  → ExtractionService.extractFromText() [LLM, async-locked]
  → DatabaseService.updateExtractedData()
  → RAGQueueService.enqueue() [fire-and-forget, lower priority]
```

### UI (ForUI)

Design system: `forui` package (shadcn/ui-inspired). Components: `FButton`, `FCard`, `FAlert`, `FDialog`, `FToast`, `FScaffold`, `FHeader`. Theming via `FThemes.zinc` in `main.dart`. See [docs/FORUI_GUIDE.md](docs/FORUI_GUIDE.md) for usage guide.

### State Management (Riverpod + Freezed)

- `@riverpod` code generation for providers, `@freezed` for immutable state classes
- Key keepAlive providers: `ScanningProvider` (scan lifecycle), `ExtractionQueue` (LLM processing), `CactusProvider` (model management)

### Routing (AutoRoute)

Type-safe routing with `@RoutePage` annotations. Routes defined in `lib/router/app_router.dart`.

### Platform Channels

- `com.example.slip_scanner/vision` — OCR operations (scanAllPhotos, cancelScanning, scanPaymentSlip, deleteSlipImage)
- `com.example.slip_scanner/progress` — Real-time callbacks (onProgress, onPartialResults) via `DispatchQueue.main.async`

### On-Device AI Pipeline (CactusLM + RAG)

**CactusService** (singleton): Manages CactusLM and CactusRAG lifecycle. Uses custom `_AsyncLock` (async mutex) to serialize all LLM operations — CactusLM is NOT thread-safe (causes EXC_BAD_ACCESS without locking). Streaming completions acquire lock at start, release when stream finishes.

**ExtractionService**: Extracts structured data (recipientName, notes, category) from OCR text via LLM. Fixed categories: food, transport, utilities, shopping, transfer, entertainment, health, education, other.

**ExtractionQueue** (provider): Event-driven background processing via `ExtractionNotifier` stream (no polling). Priority: extraction > RAG indexing. Pauses when user enters chat screen to avoid lock contention, resumes on exit.

**RAGQueueService** (singleton): Fire-and-forget indexing — doesn't block extraction if RAG fails. Indexes rich documents (amount, date, recipient, notes, category, original text).

**ChatProvider**: Builds system prompt with expense stats + RAG context (top 5 relevant records), streams LLM completion.

### iOS Native Implementation (AppDelegate.swift)

- **OCR**: Vision Framework, `.accurate` level, `th-TH` + `en-US` languages
- **Concurrency**: `OperationQueue` with max `min(ProcessorCount, 6)` concurrent ops. Thread-safe counters via `NSLock`
- **Shared helpers**: `recognizeText(from:)` → `buildSlipResult(text:amount:date:identifier:)` — both OCR paths (`processImageForPaymentSlip` batch and `scanPaymentSlip` single) use these
- **Name extraction**: `extractName(from:labelPatterns:anchorMatchIndex:)` — unified 3-tier strategy (label patterns → K Plus anchor → Make anchor), parameterized by match index (0=sender, 1=receiver)
- **RegexPatterns struct**: 40+ pre-compiled `NSRegularExpression` patterns for SCB, KBank (Make/K Plus), Dime formats
- **Buddhist Calendar**: Auto BE→Gregorian conversion (2567→2024, or short form 67→2024)

**Critical (Flutter 3.35+)**: All blocking native work must use `DispatchQueue.global()`, NOT `Task{}` which inherits MainActor context on merged threads.

### Database (SQLite, v4)

```
payment_slips:
  id, imagePath, assetId, amount, date, extractedText, createdAt,
  senderName, referenceId, senderAccount, receiverAccount, transactionTime,  -- OCR (v4)
  recipientName, notes, category,                                            -- LLM (v3)
  llmProcessingStatus ('pending'|'processing'|'completed'|'failed'),         -- LLM (v3)
  ragIndexed (0|1), updatedAt                                                -- LLM (v3)

Indexes: idx_assetId (dedup), idx_llm_status (queue), idx_referenceId (lookup)
```

Batch inserts use transactions with assetId deduplication. New inserts trigger `ExtractionNotifier.notifyNewSlips()`.

## Key Conventions

- iOS returns empty strings `""` for missing optional fields (not nil) — Flutter side uses `_nonEmpty()` helper to convert to null
- `convertSlipsInIsolate` must be a top-level function (required for `compute()` isolate compatibility)
- OCR receiver name pre-fills `recipientName`; LLM extraction overwrites if non-null
- Multi-bank regex patterns: arrays tried in priority order, first match wins
- KBank slips use positional extraction (no labels) — match index 0 = sender, index 1 = receiver
- Currency symbol is `฿` (Thai Baht), not `$`
- Shared helpers in `lib/utils/` (dialogs, formatters) and `lib/widgets/` (hero_card, slip_list_tile)

## Requirements

- **Flutter SDK**: 3.38.x+
- **iOS Deployment Target**: 15.6+
- **Xcode**: Latest for iOS development
