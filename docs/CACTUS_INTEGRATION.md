# Cactus LLM Integration Summary

This document summarizes the integration of Cactus Flutter LLM into the Avers app for AI-powered expense analysis.

## Overview

The Avers app now includes on-device AI capabilities using the Cactus Flutter plugin. Users can:
- Get AI-powered insights about their spending patterns
- Chat with an AI assistant about their expenses
- Have slips automatically enriched with extracted recipient, notes, and category data

## Architecture

### Non-Blocking Design

The key architectural decision was ensuring LLM operations never block the fast OCR scanning pipeline:

```
FAST PATH (unchanged):
Photos → iOS Vision OCR → DB insert (status='pending') → UI update
< 1 second per image

BACKGROUND PATH (async):
Timer(2s) → Query pending slips → LLM extract → Update DB → Index RAG
~5-10 seconds per slip, user doesn't wait
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ User scans photos                                           │
│ Vision OCR extracts: amount, date, raw text                 │
│ Slips saved immediately with status='pending'               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Background Extraction Queue (ExtractionProvider)            │
│ - Runs every 2 seconds when model is loaded                 │
│ - Extracts: recipientName, notes, category                  │
│ - Indexes in RAG for semantic search                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Chat/Analysis Features                                       │
│ - RAG search finds relevant expenses                        │
│ - LLM generates insights and answers questions              │
│ - Streaming responses for smooth UX                         │
└─────────────────────────────────────────────────────────────┘
```

## Files Created

### Services (2 files)

| File | Purpose |
|------|---------|
| `lib/services/cactus_service.dart` | Singleton managing CactusLM & CactusRAG lifecycle |
| `lib/services/extraction_service.dart` | LLM text extraction with structured prompts |

### Providers (8 files)

| File | Purpose |
|------|---------|
| `lib/providers/cactus_provider.dart` | Model download/initialization state |
| `lib/providers/cactus_state.dart` | Freezed state for model status |
| `lib/providers/extraction_provider.dart` | Background extraction queue management |
| `lib/providers/extraction_state.dart` | Freezed state for queue status |
| `lib/providers/chat_provider.dart` | Chat conversation with RAG context |
| `lib/providers/chat_state.dart` | Freezed state for messages |
| `lib/providers/analysis_provider.dart` | Expense insights generation |
| `lib/providers/analysis_state.dart` | Freezed state for analysis data |

### Screens (3 files)

| File | Purpose |
|------|---------|
| `lib/screens/analysis_screen.dart` | Analysis dashboard with date picker, category breakdown, insights |
| `lib/screens/chat_screen.dart` | Chat interface with streaming responses |
| `lib/screens/settings_screen.dart` | Model selection, download progress, queue status |

## Files Modified

### Database Changes

**`lib/services/database_service.dart`**
- Upgraded to version 3
- Added new columns: `recipientName`, `notes`, `category`, `llmProcessingStatus`, `ragIndexed`, `updatedAt`
- Added index on `llmProcessingStatus` for queue performance
- New methods:
  - `getSlipsWithStatus()` - Query by processing status
  - `countSlipsWithStatus()` - Count pending/failed
  - `updateLLMStatus()` - Update processing status
  - `updateExtractedData()` - Save extracted fields
  - `updateRAGIndexed()` - Mark as indexed
  - `getPaymentSlipsInRange()` - Date range queries
  - `resetFailedToStatus()` - Retry failed extractions

### Model Changes

**`lib/models/payment_slip.dart`**
- Added fields: `recipientName`, `notes`, `category`, `llmProcessingStatus`, `ragIndexed`, `updatedAt`
- Added `copyWith()` method
- Updated `toMap()` and `fromMap()`

### UI Changes

**`lib/screens/home_screen.dart`**
- Added "AI Expense Analysis" card with sparkles icon
- Added background processing indicator showing pending count

**`lib/router/app_router.dart`**
- Added routes: `AnalysisRoute`, `ChatRoute`, `SettingsRoute`

### Dependencies

**`pubspec.yaml`**
- Added `shared_preferences: ^2.2.2` for persisting model selection

## Key Features

### 1. Model Management
- User can choose between models (qwen3-0.6, gemma3-270m, etc.)
- Download progress with percentage
- Models persist across app restarts
- Unload to free memory

### 2. Background Extraction
- Runs automatically when model is loaded
- Processes one slip every 2 seconds
- Extracts:
  - **recipientName**: Who received the money
  - **notes**: Payment memo/reference
  - **category**: food, transport, utilities, shopping, transfer, entertainment, health, education, other
- Failed extractions can be retried

### 3. RAG Integration
- Each processed slip is indexed in ObjectBox vector database
- Semantic search finds relevant expenses for chat context
- Document format includes amount, date, recipient, notes, category, and original OCR text

### 4. Chat with AI
- Date range filtering
- Streaming responses for real-time feedback
- Context includes:
  - Summary statistics (total, count, average, categories)
  - RAG search results (top 5 similar expenses)
- Suggested quick questions

### 5. Expense Analysis
- Date range picker (defaults to current month)
- Category breakdown with progress bars
- Monthly trends
- AI-generated insights (when model loaded)
- Basic statistical insights (always available)

## LLM Prompts

### Extraction Prompt
```
You are analyzing Thai banking payment slip text.
Extract the following information and respond in JSON format only:
{
  "recipientName": "recipient's name or null",
  "notes": "payment notes/memo or null",
  "category": "food/transport/utilities/shopping/transfer/entertainment/health/education/other"
}
```

### Chat System Prompt
```
You are a helpful expense tracking assistant for a Thai banking slip scanner app.
Current date range filter: [dates]
Summary statistics: [stats]
Relevant expense records: [RAG results]

Guidelines:
- Be concise and helpful
- Format currency amounts clearly
- Provide actionable insights
- Answer in the same language the user uses
```

## Error Handling

| Scenario | Handling |
|----------|----------|
| Model download fails | Show error in settings, allow retry |
| Extraction fails | Mark as 'failed', show retry button |
| RAG indexing fails | Mark ragIndexed=0, retry next pass |
| Chat fails | Show error in chat, preserve history |
| Model not loaded | Disable chat button, show loading state |

## Testing the Integration

1. **Run the app**: `flutter run`
2. **Go to Home**: See "AI Expense Analysis" card
3. **Tap Analysis**: Opens analysis dashboard
4. **Go to Settings** (gear icon): Download a model
5. **Wait for download**: Progress shown in UI
6. **Return to Analysis**: AI insights now available
7. **Tap "Ask AI"**: Open chat interface
8. **Ask questions**: "What did I spend the most on?"

## Performance Considerations

- Models are NOT loaded on app startup (keeps launch fast)
- Models load on first access to Analysis/Chat screens
- Background extraction uses Timer (not continuous loop)
- RAG uses ObjectBox HNSW index for fast vector search
- Streaming responses provide immediate feedback

## Future Improvements

Potential enhancements:
- Model unloading after period of inactivity
- More expense categories
- Receipt image analysis with vision models
- Export analysis reports
- Budget setting and tracking
- Notification when monthly spending exceeds threshold
