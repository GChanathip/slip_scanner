import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Pure Dart HTTP client for LINE Messaging API.
/// No official Dart SDK exists, so this wraps the REST endpoints directly.
class LineService {
  final String channelAccessToken;
  final String channelSecret;
  final http.Client _client;

  static const _apiBase = 'https://api.line.me/v2/bot';
  static const _dataApiBase = 'https://api-data.line.me/v2/bot';

  LineService({
    required this.channelAccessToken,
    required this.channelSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $channelAccessToken',
        'Content-Type': 'application/json',
      };

  /// Verify X-Line-Signature header (HMAC-SHA256 with channel secret).
  /// Uses constant-time comparison to prevent timing attacks.
  bool verifySignature(String body, String signature) {
    final hmacSha256 = Hmac(sha256, utf8.encode(channelSecret));
    final digest = hmacSha256.convert(utf8.encode(body));
    final expected = Uint8List.fromList(digest.bytes);
    final List<int> actual;
    try {
      actual = base64.decode(signature);
    } catch (_) {
      return false;
    }
    if (expected.length != actual.length) return false;
    var result = 0;
    for (var i = 0; i < expected.length; i++) {
      result |= expected[i] ^ actual[i];
    }
    return result == 0;
  }

  /// Download image content for a message.
  Future<Uint8List> getMessageContent(String messageId) async {
    final response = await _client
        .get(
          Uri.parse('$_dataApiBase/message/$messageId/content'),
          headers: {'Authorization': 'Bearer $channelAccessToken'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get message content: ${response.statusCode}',
      );
    }
    return response.bodyBytes;
  }

  /// Send reply using replyToken (valid ~30s after webhook).
  /// Returns true on success (HTTP 200), false otherwise.
  Future<bool> replyMessage(
    String replyToken,
    List<Map<String, dynamic>> messages,
  ) async {
    final response = await _client.post(
      Uri.parse('$_apiBase/message/reply'),
      headers: _authHeaders,
      body: jsonEncode({
        'replyToken': replyToken,
        'messages': messages,
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('LINE reply failed: ${response.statusCode} ${response.body}');
      return false;
    }
    return true;
  }

  /// Send push message (for async responses after processing).
  /// Returns true on success (HTTP 200), false otherwise.
  Future<bool> pushMessage(
    String userId,
    List<Map<String, dynamic>> messages,
  ) async {
    final response = await _client.post(
      Uri.parse('$_apiBase/message/push'),
      headers: _authHeaders,
      body: jsonEncode({
        'to': userId,
        'messages': messages,
      }),
    );
    if (response.statusCode != 200) {
      debugPrint('LINE push failed: ${response.statusCode} ${response.body}');
      return false;
    }
    return true;
  }

  /// Helper: create a text message object.
  /// Truncates safely using [Characters] to avoid splitting multi-byte Thai chars.
  static Map<String, dynamic> textMessage(String text) {
    if (text.length <= 5000) {
      return {'type': 'text', 'text': text};
    }
    final truncated = text.characters.take(4997).toString();
    return {'type': 'text', 'text': '$truncated...'};
  }

  void dispose() {
    _client.close();
  }
}
