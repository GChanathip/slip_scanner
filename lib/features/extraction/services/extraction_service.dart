import 'dart:convert';
import 'package:cactus/cactus.dart';
import 'package:cactus/models/types.dart';
import 'package:flutter/foundation.dart';
import 'package:avers/core/models/category_registry.dart';
import 'package:avers/features/ai/services/cactus_service.dart';
import 'package:avers/features/category/services/category_service.dart';

/// Result of LLM extraction from slip text
class ExtractionResult {
  final String? recipientName;
  final String? notes;
  final String? category;
  final String? categorySource; // 'ai' | 'rule'

  ExtractionResult({this.recipientName, this.notes, this.category, this.categorySource});

  @override
  String toString() =>
      'ExtractionResult(recipient: $recipientName, notes: $notes, category: $category, source: $categorySource)';
}

/// Service for extracting structured data from OCR text using LLM
class ExtractionService {
  static const _systemPromptPrefix = '''You are analyzing Thai banking payment slip text.
Extract the following information and respond in JSON format only:
{
  "recipientName": "recipient's name (who received the money) or null if not found",
  "notes": "any payment notes/memo/reference or null if not found",
  "category": "one of: ''';

  static const _systemPromptSuffix = '''"
}

Rules:
- Only output valid JSON, no explanation or additional text
- For category, choose the most appropriate one based on the recipient name and context
- If you cannot determine a field, use null
- Keep recipientName concise (just the name, no account numbers)
- Notes should be brief (max 100 chars)''';

  /// Build a dynamic system prompt that includes custom category names.
  static String _buildSystemPrompt(Set<String> validCategories) {
    final categoryList = validCategories.join(', ');
    return '$_systemPromptPrefix$categoryList$_systemPromptSuffix';
  }

  /// Extract structured data from OCR text.
  ///
  /// [categoryService] is optional but strongly recommended for production use.
  /// When provided it:
  ///   - enriches the LLM prompt with custom category names
  ///   - applies rule-based category overrides after LLM extraction
  static Future<ExtractionResult> extractFromText(
    String extractedText, {
    CategoryService? categoryService,
    Set<String>? cachedValidCategories,
  }) async {
    if (!CactusService.instance.isLoaded) {
      throw Exception('Model not loaded');
    }

    // Resolve the set of valid category names (cached for batch efficiency).
    final validCategories = cachedValidCategories ??
        (categoryService != null
            ? await categoryService.getValidCategoryNames()
            : kBuiltInCategorySlugs.toSet());

    final systemPrompt = _buildSystemPrompt(validCategories);

    final messages = [
      ChatMessage(content: systemPrompt, role: 'system'),
      ChatMessage(content: 'Extract info from this Thai banking slip:\n\n$extractedText', role: 'user'),
    ];

    final result = await CactusService.instance.generateCompletion(messages);

    if (!result.success) {
      throw Exception('Extraction failed: ${result.response}');
    }

    final parsed = _parseExtractionResult(result.response, validCategories);

    // Rule-based category override.
    if (categoryService != null && parsed.recipientName != null) {
      final rule = await categoryService.findRule(parsed.recipientName!);
      if (rule != null) {
        return ExtractionResult(
          recipientName: parsed.recipientName,
          notes: parsed.notes,
          category: rule.category,
          categorySource: 'rule',
        );
      }
    }

    return ExtractionResult(
      recipientName: parsed.recipientName,
      notes: parsed.notes,
      category: parsed.category,
      categorySource: 'ai',
    );
  }

  /// Parse JSON response into ExtractionResult
  static ExtractionResult _parseExtractionResult(
    String jsonResponse,
    Set<String> validCategories,
  ) {
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
        category: _validateCategory(json['category'], validCategories),
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

  /// Validate category against the given valid names; falls back to 'other'.
  /// Checks case-sensitive first (custom categories preserve casing), then
  /// falls back to a lowercase match (built-in slugs are always lowercase).
  static String? _validateCategory(dynamic value, Set<String> validCategories) {
    if (value == null) return 'other';
    final trimmed = value.toString().trim();
    if (trimmed.isEmpty) return 'other';
    // Exact match first (preserves custom category casing)
    if (validCategories.contains(trimmed)) return trimmed;
    // Lowercase fallback (handles LLM returning "Food" for built-in "food")
    final lower = trimmed.toLowerCase();
    if (validCategories.contains(lower)) return lower;
    return 'other';
  }

  // ─── Visible for testing ────────────────────────────────────────────────

  @visibleForTesting
  static String buildSystemPromptForTest(Set<String> validCategories) =>
      _buildSystemPrompt(validCategories);

  @visibleForTesting
  static String? validateCategoryForTest(dynamic value, Set<String> validCategories) =>
      _validateCategory(value, validCategories);

  @visibleForTesting
  static Future<ExtractionResult> applyRuleOverride(
    ExtractionResult base,
    CategoryService categoryService,
  ) async {
    if (base.recipientName == null) {
      return ExtractionResult(
        recipientName: base.recipientName,
        notes: base.notes,
        category: base.category,
        categorySource: 'ai',
      );
    }
    final rule = await categoryService.findRule(base.recipientName!);
    if (rule != null) {
      return ExtractionResult(
        recipientName: base.recipientName,
        notes: base.notes,
        category: rule.category,
        categorySource: 'rule',
      );
    }
    return ExtractionResult(
      recipientName: base.recipientName,
      notes: base.notes,
      category: base.category,
      categorySource: 'ai',
    );
  }
}
