# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter iOS app that automatically scans payment slips from device photos using Apple Vision Framework OCR. The app specializes in Thai banking slips with support for Thai language text recognition, Buddhist calendar conversion, and comma-separated number formatting.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator/device
flutter run

# Build for iOS release
flutter build ios

# Run tests
flutter test

# Analyze code (includes linting)
flutter analyze

# Install iOS dependencies
cd ios && pod install
```

## Architecture Overview

### Platform Channel Integration
The app uses **dual platform channels** for Flutter-iOS communication:
- `com.example.slip_scanner/vision` - Main OCR operations (scanAllPhotos, cancelScanning, scanPaymentSlip)
- `com.example.slip_scanner/progress` - Real-time progress updates during bulk scanning

### Key Data Flow
```
Flutter UI → Platform Service → iOS AppDelegate → Vision Framework → Progress Updates → Database Storage
```

### iOS Native Implementation (AppDelegate.swift)
- **OCR Engine**: Apple Vision Framework with `th-TH` and `en-US` language support
- **Batch Processing**: Processes photos in groups of 20 with throttled progress updates
- **Thai Banking Patterns**: Prioritized regex patterns for SCB, KBank, and general Thai banking formats
- **Buddhist Calendar**: Automatic conversion from Buddhist Era (BE) to Gregorian years

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
- Buddhist calendar conversion (2567 BE → 2024 AD)
- Thai month abbreviations (`มิ.ย.`, `ม.ค.`, etc.)
- Multiple date formats (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)

## Critical Implementation Notes

### Progress Updates
- iOS sends immediate progress updates after each photo processing
- Timer-based backup updates every 0.5 seconds
- Progress data: `{total, processed, slipsFound, isComplete}`

### Platform Channel Data Types
- **From Flutter**: Method calls with string/map arguments
- **To Flutter**: Progress updates as Map<String, dynamic>
- **Batch Results**: Arrays of slip data with amount, date, text, assetId

### Error Handling
- Permission requests for photo library access
- OCR processing failures are logged but don't stop batch processing
- Database duplicate prevention via assetId checks

## File Structure

```
lib/
├── models/payment_slip.dart          # Data model with toMap/fromMap
├── services/
│   ├── platform_service.dart        # Flutter-iOS bridge
│   └── database_service.dart        # SQLite operations with batch inserts
├── screens/
│   ├── home_screen.dart             # Main UI with monthly summaries
│   ├── scanning_progress_screen.dart # Real-time progress during scanning
│   └── monthly_view_screen.dart      # Monthly spending details
ios/Runner/AppDelegate.swift          # All iOS OCR logic and Vision Framework integration
```

## Testing Thai Banking Slips

When testing OCR accuracy, use these reference formats:
- **SCB**: "จำนวนเงิน 70.00" 
- **KBank**: "จำนวน: 520.00 บาท"
- **Amounts over 999**: "1,000.00", "10,000.00" with comma separators
- **Buddhist dates**: "25 มิ.ย. 68" (25 June 2025 in BE format)

## Requirements

- **Flutter SDK**: 3.8.1+
- **iOS Deployment Target**: 15.6+
- **Xcode**: Latest for iOS development
- **Device/Simulator**: iOS device with photo library access for full testing