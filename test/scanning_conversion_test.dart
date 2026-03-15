import 'package:flutter_test/flutter_test.dart';
import 'package:avers/core/utils/slip_conversion.dart';

void main() {
  group('nonEmpty', () {
    test('returns null for null input', () {
      expect(nonEmpty(null), isNull);
    });

    test('returns null for empty string', () {
      expect(nonEmpty(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(nonEmpty('   '), isNull);
    });

    test('returns trimmed value for valid string', () {
      expect(nonEmpty(' hello '), equals('hello'));
    });

    test('returns value for non-empty string without whitespace', () {
      expect(nonEmpty('test'), equals('test'));
    });

    test('handles int input via toString', () {
      expect(nonEmpty(123), equals('123'));
    });

    test('handles zero', () {
      expect(nonEmpty(0), equals('0'));
    });
  });

  group('parseThaiDate', () {
    test('parses ISO format yyyy-MM-dd', () {
      final result = parseThaiDate('2024-01-15');
      expect(result, equals(DateTime(2024, 1, 15)));
    });

    test('parses DD-MM-YYYY format', () {
      final result = parseThaiDate('15-01-2024');
      expect(result, equals(DateTime(2024, 1, 15)));
    });

    test('parses DD/MM/YYYY from Buddhist conversion', () {
      final result = parseThaiDate('15/01/2024');
      expect(result, equals(DateTime(2024, 1, 15)));
    });

    test('parses English abbreviated month "15 Mar 2024"', () {
      final result = parseThaiDate('15 Mar 2024');
      expect(result, equals(DateTime(2024, 3, 15)));
    });

    test('parses English full month "5 March 2024"', () {
      final result = parseThaiDate('5 March 2024');
      expect(result, equals(DateTime(2024, 3, 5)));
    });

    test('parses case-insensitive month "15 JAN 2024"', () {
      final result = parseThaiDate('15 JAN 2024');
      expect(result, equals(DateTime(2024, 1, 15)));
    });

    test('handles leading/trailing whitespace', () {
      final result = parseThaiDate('  2024-06-01  ');
      expect(result, equals(DateTime(2024, 6, 1)));
    });

    test('returns null for garbage input', () {
      expect(parseThaiDate('not-a-date'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseThaiDate(''), isNull);
    });

    test('returns null for partial date', () {
      expect(parseThaiDate('2024-01'), isNull);
    });
  });

  group('convertSlipsInIsolate', () {
    test('converts full platform data to PaymentSlip', () {
      final input = [
        {
          'assetId': 'test-001',
          'amount': 1500.0,
          'date': '2024-01-15',
          'text': 'OCR text here',
          'receiverName': 'สมหญิง รักดี',
          'senderName': 'สมชาย ใจดี',
          'referenceId': 'ABC123',
          'senderAccount': '456-7',
          'receiverAccount': '789-0',
          'time': '14:30',
        }
      ];

      final result = convertSlipsInIsolate(input);

      expect(result.length, 1);
      expect(result[0].amount, 1500.0);
      expect(result[0].assetId, 'test-001');
      expect(result[0].imagePath, 'test-001');
      expect(result[0].extractedText, 'OCR text here');
      expect(result[0].recipientName, 'สมหญิง รักดี');
      expect(result[0].senderName, 'สมชาย ใจดี');
      expect(result[0].referenceId, 'ABC123');
      expect(result[0].senderAccount, '456-7');
      expect(result[0].receiverAccount, '789-0');
      expect(result[0].transactionTime, '14:30');
      expect(result[0].date, equals(DateTime(2024, 1, 15)));
    });

    test('converts empty strings to null', () {
      final input = [
        {
          'assetId': 'test-002',
          'amount': 100.0,
          'date': '2024-01-15',
          'text': 'some text',
          'receiverName': '',
          'senderName': '',
          'referenceId': '',
          'senderAccount': '',
          'receiverAccount': '',
          'time': '',
        }
      ];

      final result = convertSlipsInIsolate(input);

      expect(result[0].recipientName, isNull);
      expect(result[0].senderName, isNull);
      expect(result[0].referenceId, isNull);
      expect(result[0].senderAccount, isNull);
      expect(result[0].receiverAccount, isNull);
      expect(result[0].transactionTime, isNull);
    });

    test('handles int amount', () {
      final input = [
        {
          'assetId': 'test-003',
          'amount': 500,
          'date': '2024-06-01',
          'text': 'text',
        }
      ];

      final result = convertSlipsInIsolate(input);
      expect(result[0].amount, 500.0);
    });

    test('handles string amount', () {
      final input = [
        {
          'assetId': 'test-004',
          'amount': '1234.56',
          'date': '2024-06-01',
          'text': 'text',
        }
      ];

      final result = convertSlipsInIsolate(input);
      expect(result[0].amount, 1234.56);
    });

    test('handles null amount as 0.0', () {
      final input = [
        {
          'assetId': 'test-005',
          'amount': null,
          'date': '2024-06-01',
          'text': 'text',
        }
      ];

      final result = convertSlipsInIsolate(input);
      expect(result[0].amount, 0.0);
    });

    test('handles missing optional fields gracefully', () {
      final input = [
        {
          'assetId': 'test-006',
          'amount': 100.0,
          'date': '2024-01-01',
          'text': 'minimal data',
        }
      ];

      final result = convertSlipsInIsolate(input);
      expect(result[0].recipientName, isNull);
      expect(result[0].senderName, isNull);
      expect(result[0].referenceId, isNull);
    });

    test('converts multiple slips', () {
      final input = [
        {'assetId': 'a', 'amount': 100.0, 'date': '2024-01-01', 'text': 't1'},
        {'assetId': 'b', 'amount': 200.0, 'date': '2024-02-01', 'text': 't2'},
        {'assetId': 'c', 'amount': 300.0, 'date': '2024-03-01', 'text': 't3'},
      ];

      final result = convertSlipsInIsolate(input);
      expect(result.length, 3);
      expect(result[0].amount, 100.0);
      expect(result[1].amount, 200.0);
      expect(result[2].amount, 300.0);
    });
  });
}
