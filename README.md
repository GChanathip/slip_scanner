# Avers
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/GChanathip/slip_scanner?utm_source=oss&utm_medium=github&utm_campaign=GChanathip%2Fslip_scanner&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

Flutter app (iOS + macOS) that scans payment slips using Apple Vision Framework OCR. Specializes in Thai banking slips (SCB, KBank Make/K Plus, Dime) with Thai language text recognition, Buddhist calendar conversion, and on-device LLM extraction via CactusLM.

**iOS** — Scan slips from your photo library, view expense analysis, and chat with an AI assistant about your spending.

**macOS** — Run a LINE bot server that receives slip images via LINE chat, processes them through the same OCR pipeline, and replies with extracted payment data. Text queries are answered by CactusLM with RAG context.

## Requirements

- Flutter SDK 3.38+
- Xcode (latest)
- CocoaPods
- Apple Silicon Mac (arm64) — required for CactusLM

### Platform-Specific

| | iOS | macOS |
|---|---|---|
| **Deployment target** | 15.6+ | 13.0+ |
| **Device** | iPhone/iPad or Simulator | Apple Silicon Mac |
| **Entitlements** | Photo library access | Network server + client, JIT |

## Getting Started

### iOS Setup

```bash
# 1. Install dependencies
flutter pub get
cd ios && pod install && cd ..

# 2. Generate code (Riverpod, Freezed, AutoRoute)
dart run build_runner build --delete-conflicting-outputs

# 3. Run on iOS simulator or device
flutter run
```

Grant photo library access when prompted, then tap "Scan All Photos" to begin.

### macOS Setup (LINE Bot Server)

```bash
# 1. Install dependencies
flutter pub get
cd macos && pod install && cd ..

# 2. Generate code
dart run build_runner build --delete-conflicting-outputs

# 3. Run on macOS
flutter run -d macos
```

The macOS app opens a server dashboard. To set up the LINE bot:

1. Create a LINE Bot at [LINE Developers Console](https://developers.line.biz/console/)
2. Copy the **Channel Access Token** and **Channel Secret** into the dashboard
3. Click **Start** — this downloads the CactusLM model (first run only), starts the extraction queue, and begins the HTTP server
4. Expose the server with [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/):
   ```bash
   cloudflared tunnel --url http://localhost:8080
   ```
5. Set the tunnel URL as your LINE webhook: `https://<your-tunnel>.trycloudflare.com/webhook/line`
6. Send a slip image to your LINE bot

The dashboard shows server status, AI engine status (model loaded/loading), and extraction queue progress.

## Development Commands

```bash
flutter run                  # Run on iOS simulator/device
flutter run -d macos         # Run macOS target (LINE bot server)
flutter build ios            # Build for iOS release
flutter analyze              # Static analysis (includes riverpod_lint)
dart run build_runner build --delete-conflicting-outputs  # Generate code
dart run build_runner watch  # Watch mode for code generation
```

## Testing

### Dart Tests

```bash
flutter test                                        # Run all Dart tests
flutter test test/scanning_conversion_test.dart      # Run a specific test file
flutter test --reporter expanded                     # Verbose output
```

### iOS XCTests (OCR & Regex Extraction)

Requires an iOS Simulator. Tests the native OCR extraction pipeline: amounts, dates, names, accounts, reference IDs, Buddhist calendar conversion, and `buildSlipResult` assembly across all bank formats (SCB, KBank Make/K Plus, Dime).

```bash
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RunnerTests/OCRExtractionTests \
  -only-testing:RunnerTests/BuddhistCalendarTests \
  -only-testing:RunnerTests/BuildSlipResultTests
```

### Test Structure

- `test/scanning_conversion_test.dart` -- Dart unit tests for slip data conversion: `nonEmpty` helper, `parseThaiDate` (ISO, DD/MM/YYYY, English month formats), and `convertSlipsInIsolate` (platform data to `PaymentSlip` model, type coercion, optional field handling).
- `ios/RunnerTests/OCRExtractionTests.swift` -- Text-based extraction tests for all bank formats: amount, date, reference ID, name, account number, and time extraction.
- `ios/RunnerTests/BuddhistCalendarTests.swift` -- Buddhist year detection/conversion (4-digit BE, 2-digit BE) and `normalizeToISODate` format handling.
- `ios/RunnerTests/BuildSlipResultTests.swift` -- Full text-to-dictionary assembly tests, empty field handling, and truncation behavior.
- `ios/RunnerTests/OCRImageTests.swift` -- Template for image-based full-pipeline tests (add slip images to `Fixtures/Images/`).
- `ios/RunnerTests/Fixtures/` -- OCR text fixtures per bank (SCBFixtures, KBankMakeFixtures, KBankPlusFixtures, DimeFixtures) with expected extraction values.

### Adding a Regression Test

When a slip doesn't parse correctly:

1. Get the OCR text (from `extractedText` in the database or scanner log)
2. Add it as a new static constant in the appropriate bank fixture file in `ios/RunnerTests/Fixtures/`
3. Add expected values to the `Expected` struct
4. Write a one-line test assertion in the relevant test file
5. Fix the regex/extraction logic, then run all tests to verify no regressions

### What to Test Manually

Since the app relies on platform channels and native APIs, some features require manual testing:

**iOS (real device)**
- **Photo scanning**: Grant photo library access, trigger a scan, verify slips are detected and saved
- **iCloud photos**: Ensure iCloud-only photos are skipped gracefully with a count shown
- **LLM extraction**: Verify CactusLM extracts recipient name, notes, and category from OCR text
- **Chat**: Open the chat screen, confirm extraction pauses, and LLM responds with expense context

**macOS (LINE bot)**
- **Server lifecycle**: Start/stop server from dashboard, verify port binding
- **LINE image**: Send a slip image to LINE bot, verify OCR summary is returned
- **LINE text query**: Send a text message, verify LLM responds with expense context
- **Model status**: Verify dashboard shows model loading progress and extraction queue status

## Architecture

### Screen Navigation

```mermaid
flowchart LR
    subgraph ios_screens["iOS"]
        Home[Home Screen]
        Scan[Scanning Progress]
        Detail[Slip Detail]
        Monthly[Monthly View]
        Analysis[Analysis]
        Chat[Chat AI]
        Settings[Settings]

        Home -->|Scan All Photos| Scan
        Home -->|Tap slip| Detail
        Home -->|Monthly| Monthly
        Home -->|Analysis| Analysis
        Home -->|Settings| Settings
        Monthly -->|Tap slip| Detail
        Analysis -->|Ask AI| Chat
        Home -->|Ask AI| Chat
    end

    subgraph macos_screens["macOS"]
        Dashboard[Server Dashboard]
    end
```

Platform routing in `main.dart`: `Platform.isMacOS` opens `ServerDashboardRoute`, iOS opens the default home.

### Processing Pipeline (iOS)

```mermaid
flowchart TD
    subgraph ios["iOS Native (Background Threads)"]
        Photos[(Photo Library)]
        PS[PhotoScanner<br/><i>OperationQueue max 6</i>]
        OCR[OCRService<br/><i>Vision Framework</i>]
        Regex[RegexPatterns<br/><i>40+ NSRegularExpression</i>]

        Photos -->|PHAsset images| PS
        PS -->|CGImage| OCR
        OCR -->|raw text| Regex
        Regex -->|amount, date, names,<br/>accounts, referenceId| PS
    end

    subgraph channels["Platform Channels"]
        Progress[onProgress<br/><i>total, processed,<br/>slipsFound, iCloudSkipped</i>]
        Partial[onPartialResults<br/><i>slip batches</i>]
    end

    subgraph flutter["Flutter (Dart)"]
        SP[ScanningProvider]
        DB[(SQLite v5<br/>payment_slips)]
        EN{{ExtractionNotifier}}
        EQ[ExtractionQueue<br/><i>ref-counted pause</i>]
        ES[ExtractionService]
        RAG[RAGQueueService]
        CP[ChatProvider]

        SP -->|insertPaymentSlipsBatch| DB
        DB -->|notifyNewSlips| EN
        EN -->|stream event| EQ
        EQ -->|pending slips| ES
        ES -->|recipientName,<br/>notes, category| DB
        EQ -->|enqueue| RAG
        RAG -->|index documents| Cactus
        CP -->|searchRAG + stats| Cactus
    end

    subgraph llm["On-Device LLM"]
        Cactus[CactusService<br/><i>_AsyncLock serialized</i>]
    end

    PS --> Progress & Partial
    Progress --> SP
    Partial -->|immediate _insertBatch| SP
    ES <-->|generateCompletion<br/><i>locked</i>| Cactus
    CP <-->|generateCompletionStream<br/><i>locked</i>| Cactus
```

### Processing Pipeline (macOS LINE Bot)

```mermaid
flowchart TD
    LINE[LINE User] -->|image or text| Webhook[POST /webhook/line]
    Webhook -->|verify HMAC-SHA256| Handler[LineWebhookHandler]

    Handler -->|image| ImgFlow[SlipProcessorService]
    ImgFlow -->|processImageData| Native[macOS SlipProcessor<br/><i>Vision OCR</i>]
    Native -->|slip result| Convert[convertSlipsInIsolate]
    Convert -->|PaymentSlip| DB[(SQLite)]
    DB -->|notifyNewSlips| EQ[ExtractionQueue<br/><i>background LLM</i>]
    ImgFlow -->|formatted summary| Reply[LineService.reply]

    Handler -->|text| TextFlow[ChatQueryService]
    TextFlow -->|RAG + stats| LLM[CactusService<br/><i>generateCompletion</i>]
    LLM -->|response| Reply

    Reply -->|push or reply| LINE
```

### LLM Lock Contention Avoidance

```mermaid
sequenceDiagram
    participant EQ as ExtractionQueue
    participant Lock as CactusService._AsyncLock
    participant Chat as ChatScreen

    EQ->>Lock: generateCompletion (extraction)
    Lock-->>EQ: result

    Chat->>EQ: pauseExtraction()
    Note over EQ: _pauseCount++ → loop yields

    Chat->>Lock: generateCompletionStream (chat)
    Lock-->>Chat: streaming tokens

    Chat->>EQ: resumeExtraction()
    Note over EQ: _pauseCount-- → loop resumes

    EQ->>Lock: generateCompletion (next slip)
    Lock-->>EQ: result
```

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation including database schema, key conventions, and native implementation details.
