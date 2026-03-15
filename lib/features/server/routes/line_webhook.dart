import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import 'package:avers/features/chat/services/chat_query_service.dart';
import 'package:avers/features/server/services/line_service.dart';
import 'package:avers/features/server/services/slip_processor_service.dart';

/// Handles incoming LINE webhook POST requests.
class LineWebhookHandler {
  final LineService? lineService;

  /// Recent webhook events for dashboard display.
  final List<WebhookEvent> recentEvents = [];
  static const _maxEvents = 50;

  LineWebhookHandler({required this.lineService});

  /// Maximum webhook body size (10 MB).
  static const _maxBodySize = 10 * 1024 * 1024;

  Future<Response> handle(Request request) async {
    if (lineService == null) {
      return Response(503, body: 'LINE service not configured');
    }

    // 0. Guard against oversized payloads
    final contentLength = request.contentLength;
    if (contentLength != null && contentLength > _maxBodySize) {
      return Response(413, body: 'Payload too large');
    }

    // 1. Read body
    final body = await request.readAsString();
    if (body.length > _maxBodySize) {
      return Response(413, body: 'Payload too large');
    }

    // 2. Verify signature
    final signature = request.headers['x-line-signature'];
    if (signature == null || !lineService!.verifySignature(body, signature)) {
      return Response(401, body: 'Invalid signature');
    }

    // 3. Parse webhook body
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body);
    } catch (e) {
      return Response(400, body: 'Invalid JSON');
    }

    // 4. Return 200 OK immediately, process events async
    final events = payload['events'] as List<dynamic>? ?? [];
    for (final event in events) {
      unawaited(_processEvent(event));
    }

    return Response.ok('OK');
  }

  Future<void> _processEvent(dynamic event) async {
    try {
      final type = event['type'] as String?;
      final replyToken = event['replyToken'] as String?;
      final source = event['source'] as Map<String, dynamic>?;
      final userId = source?['userId'] as String?;

      if (type == 'message') {
        final message = event['message'] as Map<String, dynamic>?;
        final messageType = message?['type'] as String?;

        if (messageType == 'image') {
          final messageId = message?['id']?.toString();
          if (messageId == null) {
            debugPrint('Missing message ID');
            return;
          }
          await _handleImageMessage(
            messageId: messageId,
            replyToken: replyToken,
            userId: userId,
          );
        } else if (messageType == 'text') {
          final text = message?['text'] as String?;
          if (text == null) {
            debugPrint('Missing message text');
            return;
          }
          await _handleTextMessage(
            text: text,
            replyToken: replyToken,
            userId: userId,
          );
        }
      }
    } catch (e, st) {
      debugPrint('Error processing webhook event: $e\n$st');
      _addEvent(WebhookEvent(type: 'error', detail: 'Unhandled: $e'));
    }
  }

  Future<void> _handleImageMessage({
    required String messageId,
    String? replyToken,
    String? userId,
  }) async {
    _addEvent(WebhookEvent(type: 'image', detail: 'Processing image...'));

    try {
      // Download image from LINE CDN
      final imageData = await lineService!.getMessageContent(messageId);

      // Process through OCR pipeline
      final result = await SlipProcessorService.processLineImage(imageData);

      // Reply with the actual result (replyToken is still valid for ~30s)
      final resultMessages = [LineService.textMessage(result)];
      if (replyToken != null) {
        final replied = await lineService!.replyMessage(replyToken, resultMessages);
        if (!replied && userId != null) {
          await lineService!.pushMessage(userId, resultMessages);
        }
      } else if (userId != null) {
        await lineService!.pushMessage(userId, resultMessages);
      }

      _addEvent(WebhookEvent(type: 'image', detail: 'Processed: ${result.split('\n').first}'));
    } catch (e) {
      debugPrint('Error processing image: $e');
      // Try to notify user about the error
      try {
        final errorMessages = [
          LineService.textMessage('Sorry, I could not process this image. Please try again.'),
        ];
        if (replyToken != null) {
          final replied = await lineService!.replyMessage(replyToken, errorMessages);
          if (!replied && userId != null) {
            await lineService!.pushMessage(userId, errorMessages);
          }
        } else if (userId != null) {
          await lineService!.pushMessage(userId, errorMessages);
        }
      } catch (replyError) {
        debugPrint('Failed to send error reply: $replyError');
      }
      _addEvent(WebhookEvent(type: 'image', detail: 'Error: $e'));
    }
  }

  Future<void> _handleTextMessage({
    required String text,
    String? replyToken,
    String? userId,
  }) async {
    _addEvent(WebhookEvent(type: 'text', detail: text));

    try {
      // Process query through LLM
      final response = await ChatQueryService.processQuery(text);

      final responseMessages = [LineService.textMessage(response)];
      if (replyToken != null) {
        final replied = await lineService!.replyMessage(replyToken, responseMessages);
        if (!replied && userId != null) {
          await lineService!.pushMessage(userId, responseMessages);
        }
      } else if (userId != null) {
        await lineService!.pushMessage(userId, responseMessages);
      }

      _addEvent(WebhookEvent(
        type: 'text',
        detail: 'Reply sent (${response.length} chars)',
      ));
    } catch (e) {
      debugPrint('Error processing text query: $e');
      try {
        final errorMessages = [
          LineService.textMessage('Sorry, I encountered an error. Please try again.'),
        ];
        if (replyToken != null) {
          final replied = await lineService!.replyMessage(replyToken, errorMessages);
          if (!replied && userId != null) {
            await lineService!.pushMessage(userId, errorMessages);
          }
        } else if (userId != null) {
          await lineService!.pushMessage(userId, errorMessages);
        }
      } catch (replyError) {
        debugPrint('Failed to send error reply: $replyError');
      }
      _addEvent(WebhookEvent(type: 'text', detail: 'Error: $e'));
    }
  }

  void _addEvent(WebhookEvent event) {
    recentEvents.insert(0, event);
    if (recentEvents.length > _maxEvents) {
      recentEvents.removeLast();
    }
  }
}

class WebhookEvent {
  final String type;
  final String detail;
  final DateTime timestamp;

  WebhookEvent({
    required this.type,
    required this.detail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
