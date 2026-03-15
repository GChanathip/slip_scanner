import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../services/chat_query_service.dart';
import '../../services/line_service.dart';
import '../../services/slip_processor_service.dart';

/// Handles incoming LINE webhook POST requests.
class LineWebhookHandler {
  final LineService? lineService;

  /// Recent webhook events for dashboard display.
  final List<WebhookEvent> recentEvents = [];
  static const _maxEvents = 50;

  LineWebhookHandler({required this.lineService});

  Future<Response> handle(Request request) async {
    if (lineService == null) {
      return Response(503, body: 'LINE service not configured');
    }

    // 1. Read body
    final body = await request.readAsString();

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
          await _handleImageMessage(
            messageId: message!['id'].toString(),
            replyToken: replyToken,
            userId: userId,
          );
        } else if (messageType == 'text') {
          await _handleTextMessage(
            text: message!['text'] as String,
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
      if (replyToken != null) {
        await lineService!.replyMessage(replyToken, [
          LineService.textMessage(result),
        ]);
      } else if (userId != null) {
        await lineService!.pushMessage(userId, [
          LineService.textMessage(result),
        ]);
      }

      _addEvent(WebhookEvent(type: 'image', detail: 'Processed: ${result.split('\n').first}'));
    } catch (e) {
      debugPrint('Error processing image: $e');
      // replyToken may still be valid if image download/OCR failed quickly
      if (replyToken != null) {
        await lineService!.replyMessage(replyToken, [
          LineService.textMessage('Sorry, I could not process this image. Please try again.'),
        ]);
      } else if (userId != null) {
        await lineService!.pushMessage(userId, [
          LineService.textMessage('Sorry, I could not process this image. Please try again.'),
        ]);
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

      if (replyToken != null) {
        await lineService!.replyMessage(replyToken, [
          LineService.textMessage(response),
        ]);
      } else if (userId != null) {
        await lineService!.pushMessage(userId, [
          LineService.textMessage(response),
        ]);
      }

      _addEvent(WebhookEvent(
        type: 'text',
        detail: 'Reply sent (${response.length} chars)',
      ));
    } catch (e) {
      debugPrint('Error processing text query: $e');
      if (replyToken != null) {
        await lineService!.replyMessage(replyToken, [
          LineService.textMessage('Sorry, I encountered an error. Please try again.'),
        ]);
      } else if (userId != null) {
        await lineService!.pushMessage(userId, [
          LineService.textMessage('Sorry, I encountered an error. Please try again.'),
        ]);
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
