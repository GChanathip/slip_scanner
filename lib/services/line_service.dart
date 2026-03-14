import 'dart:convert';

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
  bool verifySignature(String body, String signature) {
    final hmacSha256 = Hmac(sha256, utf8.encode(channelSecret));
    final digest = hmacSha256.convert(utf8.encode(body));
    final expected = base64.encode(digest.bytes);
    return expected == signature;
  }

  /// Download image content for a message.
  Future<Uint8List> getMessageContent(String messageId) async {
    final response = await _client.get(
      Uri.parse('$_dataApiBase/message/$messageId/content'),
      headers: {'Authorization': 'Bearer $channelAccessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get message content: ${response.statusCode} ${response.body}',
      );
    }
    return response.bodyBytes;
  }

  /// Send reply using replyToken (valid ~30s after webhook).
  Future<void> replyMessage(
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
    }
  }

  /// Send push message (for async responses after processing).
  Future<void> pushMessage(
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
    }
  }

  /// Helper: create a text message object.
  static Map<String, dynamic> textMessage(String text) => {
        'type': 'text',
        'text': text.length > 5000 ? '${text.substring(0, 4997)}...' : text,
      };

  void dispose() {
    _client.close();
  }
}
