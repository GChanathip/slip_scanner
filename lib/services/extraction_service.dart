import 'dart:convert';
import 'package:cactus/cactus.dart';
import 'package:cactus/models/types.dart';
import '../models/category_registry.dart';
import 'cactus_service.dart';

/// Result of LLM extraction from slip text
class ExtractionResult {
  final String? recipientName;
  final String? notes;
  final String? category;

  ExtractionResult({this.recipientName, this.notes, this.category});

  @override
  String toString() => 'ExtractionResult(recipient: $recipientName, notes: $notes, category: $category)';
}

/// Service for extracting structured data from OCR text using LLM
class ExtractionService {
  static const _systemPrompt = '''You are analyzing Thai banking payment slip text.
Extract the following information and respond in JSON format only:
{
  "recipientName": "recipient's name (who received the money) or null if not found",
  "notes": "any payment notes/memo/reference or null if not found",
  "category": "one of: food, transport, utilities, shopping, transfer, entertainment, health, education, rent, subscriptions, groceries, personal_care, gifts, other"
}

Rules:
- Only output valid JSON, no explanation or additional text
- For category, choose the most appropriate one based on the recipient name and context
- If you cannot determine a field, use null
- Keep recipientName concise (just the name, no account numbers)
- Notes should be brief (max 100 chars)''';

  /// Extract structured data from OCR text
  static Future<ExtractionResult> extractFromText(String extractedText) async {
    if (!CactusService.instance.isLoaded) {
      throw Exception('Model not loaded');
    }

    final messages = [
      ChatMessage(content: _systemPrompt, role: 'system'),
      ChatMessage(content: 'Extract info from this Thai banking slip:\n\n$extractedText', role: 'user'),
    ];

    final result = await CactusService.instance.generateCompletion(messages);

    if (result.success) {
      return _parseExtractionResult(result.response);
    }
    throw Exception('Extraction failed: ${result.response}');
  }

  /// Parse JSON response into ExtractionResult
  static ExtractionResult _parseExtractionResult(String jsonResponse) {
    try {
      // Try to extract JSON from the response (in case there's extra text)
      String jsonStr = jsonResponse.trim();

      // Find JSON object in response
      final startIdx = jsonStr.indexOf('{');
      final endIdx = jsonStr.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ExtractionResult(
        recipientName: _cleanString(json['recipientName']),
        notes: _cleanString(json['notes']),
        category: _validateCategory(json['category']),
      );
    } catch (e) {
      // Return empty result on parse failure
      return ExtractionResult();
    }
  }

  /// Clean and validate string fields
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    return str;
  }

  /// Validate category is one of the allowed values
  static String? _validateCategory(dynamic value) {
    if (value == null) return 'other';
    final str = value.toString().toLowerCase().trim();
    return validateCategorySlug(str);
  }
}
