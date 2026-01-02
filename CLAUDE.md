# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important

This project focuses on **iOS only** - ignore Android implementation for now.

## Project Overview

Flutter iOS app that scans payment slips from device photos using Apple Vision Framework OCR. Specializes in Thai banking slips with Thai language text recognition, Buddhist calendar conversion, and comma-separated number formatting.

## Development Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on iOS simulator/device
flutter build ios            # Build for iOS release
flutter test                 # Run tests
flutter analyze              # Analyze code (includes linting)
cd ios && pod install        # Install iOS dependencies
```

## Architecture Overview

### Flutter 3.35+ Merged Thread Consideration

Flutter 3.35+ merges the Dart UI thread with the native platform thread. **Critical**: All blocking native work must run on explicit background threads using `DispatchQueue.global()`, NOT `Task{}` which inherits MainActor context.

### Platform Channel Integration

Dual platform channels for Flutter-iOS communication:
- `com.example.slip_scanner/vision` - OCR operations (scanAllPhotos, cancelScanning, scanPaymentSlip)
- `com.example.slip_scanner/progress` - Real-time progress updates via `onProgress` and `onPartialResults` callbacks

### Data Flow

```
Flutter UI → PlatformService → iOS AppDelegate (background thread) → Vision Framework → Progress Stream → Database
```

### iOS Native Implementation (AppDelegate.swift)

- **OCR Engine**: Apple Vision Framework with `.accurate` recognition, `th-TH` and `en-US` languages
- **Concurrency**: `OperationQueue` with max 6 concurrent operations (no chunking - streams per-image)
- **Thread Safety**: `NSLock` for counters, `DispatchQueue.main.async` for Flutter callbacks
- **Background Processing**: All OCR runs on `DispatchQueue.global(qos: .userInitiated)`
- **Regex Patterns**: Pre-compiled static patterns for Thai banking formats (SCB, KBank)
- **Buddhist Calendar**: Automatic BE to Gregorian conversion (2567 BE → 2024 AD)

### Database Schema

SQLite database (`payment_slips.db`) with duplicate prevention via `assetId` indexing:
```sql
payment_slips: id, imagePath, assetId, amount, date, extractedText, createdAt
```

## Thai Language OCR Specifics

### Amount Extraction Patterns (Priority Order)
1. `จำนวนเงิน 1,234.56` (SCB format)
2. `จำนวน: 1,234.56 บาท` (KBank format)
3. `1,234.56 บาท` (General format)
4. Comma separator support for amounts over 999

### Date Parsing
- Buddhist calendar conversion (2567 BE → 2024 AD, or short form: 67 → 2024)
- Thai month abbreviations (`มิ.ย.`, `ม.ค.`, etc.)
- Multiple date formats (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)

## Stream Architecture

Real-time updates during scanning with no throttling:

```dart
PlatformService.getProgressStream()      // {total, processed, slipsFound, isComplete}
PlatformService.getPartialResultsStream() // Batched every 10 slips found
```

iOS sends updates after every image processed via `DispatchQueue.main.async` (non-blocking).

## Key Files

| File | Purpose |
|------|---------|
| `ios/Runner/AppDelegate.swift` | All iOS OCR logic, Vision Framework, concurrency |
| `lib/services/platform_service.dart` | Flutter-iOS bridge, stream management |
| `lib/services/database_service.dart` | SQLite operations, batch inserts with dedup |
| `lib/screens/scanning_progress_screen.dart` | Real-time progress UI |

## Requirements

- **Flutter SDK**: 3.35+ (merged thread model)
- **iOS Deployment Target**: 15.6+
- **Xcode**: Latest for iOS development
