import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ReferenceCodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const String _numbers = '0123456789';
  static final Random _random = Random();

  /// Generates a simple alphanumeric reference code
  /// Format: ABC123DEF (9 characters)
  static String generateSimpleReference({int length = 9}) {
    return List.generate(
      length,
      (index) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }

  /// Generates a structured reference code with prefix
  /// Format: SMS-20241216-ABC123 (prefix + date + random)
  static String generateStructuredReference({
    String prefix = 'SMS',
    bool includeDate = true,
    int randomLength = 6,
  }) {
    final buffer = StringBuffer();

    // Add prefix
    buffer.write(prefix.toUpperCase());
    buffer.write('-');

    // Add date if requested
    if (includeDate) {
      final now = DateTime.now();
      buffer.write(
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
      buffer.write('-');
    }

    // Add random part
    final randomPart = List.generate(
      randomLength,
      (index) => _chars[_random.nextInt(_chars.length)],
    ).join();

    buffer.write(randomPart);

    return buffer.toString();
  }

  /// Generates a numeric-only reference code
  /// Format: 123456789 (9 digits)
  static String generateNumericReference({int length = 9}) {
    return List.generate(
      length,
      (index) => _numbers[_random.nextInt(_numbers.length)],
    ).join();
  }

  /// Generates a timestamp-based reference code
  /// Format: 20241216143025ABC (timestamp + random suffix)
  static String generateTimestampReference({int suffixLength = 3}) {
    final now = DateTime.now();
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final suffix = List.generate(
      suffixLength,
      (index) => _chars[_random.nextInt(_chars.length)],
    ).join();

    return '$timestamp$suffix';
  }

  /// Generates a UUID-like reference code (shortened)
  /// Format: 12AB34CD-56EF-78GH (shorter version of UUID)
  static String generateUUIDLikeReference() {
    String generateSegment(int length) {
      return List.generate(
        length,
        (index) => _chars[_random.nextInt(_chars.length)],
      ).join();
    }

    return '${generateSegment(8)}-${generateSegment(4)}-${generateSegment(4)}';
  }

  /// Generates a hash-based reference code using school ID and timestamp
  /// Format: HSH-ABC123DEF (hash-based for uniqueness)
  static String generateHashReference({
    required String schoolId,
    String prefix = 'HSH',
    int length = 9,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final input = '$schoolId-$now-${_random.nextInt(10000)}';
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes).toString();

    // Take first characters and convert to uppercase alphanumeric
    final hashPart = hash
        .substring(0, length - prefix.length - 1)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    return '$prefix-$hashPart';
  }

  /// Generates a sequential reference code with prefix and counter
  /// Note: In a real app, you'd want to store the counter in persistent storage
  static String generateSequentialReference({
    String prefix = 'TOP',
    required int counter,
    int paddingLength = 6,
  }) {
    final paddedCounter = counter.toString().padLeft(paddingLength, '0');
    return '$prefix$paddedCounter';
  }

  /// Generates a bank-style reference code
  /// Format: 240101001234 (YYMMDD + sequential number)
  static String generateBankStyleReference({
    required int sequentialNumber,
    int sequentialPadding = 6,
  }) {
    final now = DateTime.now();
    final datePart = '${(now.year % 100).toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final seqPart = sequentialNumber.toString().padLeft(sequentialPadding, '0');

    return '$datePart$seqPart';
  }

  /// Generates a mobile money style reference code
  /// Format: MM240101ABC123 (MM + date + random)
  static String generateMobileMoneyReference() {
    final now = DateTime.now();
    final datePart = '${(now.year % 100).toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final randomPart =
        List.generate(6, (index) => _chars[_random.nextInt(_chars.length)])
            .join();

    return 'MM$datePart$randomPart';
  }

  /// Generates a custom reference with specific pattern
  /// Pattern examples: "XXX-999-XXX", "999XXX999", etc.
  /// X = random letter, 9 = random number, - = literal dash
  static String generateCustomPattern(String pattern) {
    final buffer = StringBuffer();

    for (int i = 0; i < pattern.length; i++) {
      final char = pattern[i];
      switch (char) {
        case 'X':
          buffer.write(_chars[_random.nextInt(26)]); // Letters only
          break;
        case '9':
          buffer.write(_numbers[_random.nextInt(_numbers.length)]);
          break;
        case '#':
          buffer.write(
              _chars[_random.nextInt(_chars.length)]); // Letters + numbers
          break;
        default:
          buffer.write(char); // Literal character
          break;
      }
    }

    return buffer.toString();
  }

  /// Validates if a reference code matches expected patterns
  static bool validateReferenceCode(String code, {String? pattern}) {
    if (code.isEmpty) return false;

    if (pattern != null) {
      // Custom pattern validation
      if (code.length != pattern.length) return false;

      for (int i = 0; i < pattern.length; i++) {
        final patternChar = pattern[i];
        final codeChar = code[i];

        switch (patternChar) {
          case 'X':
            if (!RegExp(r'[A-Z]').hasMatch(codeChar)) return false;
            break;
          case '9':
            if (!RegExp(r'[0-9]').hasMatch(codeChar)) return false;
            break;
          case '#':
            if (!RegExp(r'[A-Z0-9]').hasMatch(codeChar)) return false;
            break;
          default:
            if (codeChar != patternChar) return false;
            break;
        }
      }
      return true;
    }

    // General validation - alphanumeric with possible dashes
    return RegExp(r'^[A-Z0-9-]+$').hasMatch(code) && code.length >= 6;
  }

  /// Generates multiple unique reference codes at once
  static List<String> generateMultipleReferences({
    required int count,
    ReferenceType type = ReferenceType.structured,
    String prefix = 'SMS',
  }) {
    final references = <String>{};

    while (references.length < count) {
      String reference;
      switch (type) {
        case ReferenceType.simple:
          reference = generateSimpleReference();
          break;
        case ReferenceType.structured:
          reference = generateStructuredReference(prefix: prefix);
          break;
        case ReferenceType.numeric:
          reference = generateNumericReference();
          break;
        case ReferenceType.timestamp:
          reference = generateTimestampReference();
          break;
        case ReferenceType.uuid:
          reference = generateUUIDLikeReference();
          break;
        case ReferenceType.mobileMoneyStyle:
          reference = generateMobileMoneyReference();
          break;
      }
      references.add(reference);

      // Small delay to ensure timestamp-based codes are unique
      if (type == ReferenceType.timestamp) {
        Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return references.toList();
  }

  /// Gets a human-readable description of the reference code
  static String getReferenceDescription(String code) {
    if (code.startsWith('SMS-')) {
      return 'SMS Top-up Reference';
    } else if (code.startsWith('MM')) {
      return 'Mobile Money Reference';
    } else if (code.startsWith('HSH-')) {
      return 'Hash-based Reference';
    } else if (code.startsWith('SEQ-')) {
      return 'Sequential Reference';
    } else if (code.contains('-')) {
      return 'Structured Reference Code';
    } else if (RegExp(r'^\d+$').hasMatch(code)) {
      return 'Numeric Reference Code';
    } else {
      return 'Reference Code';
    }
  }
}

enum ReferenceType {
  simple,
  structured,
  numeric,
  timestamp,
  uuid,
  mobileMoneyStyle,
}

/// Extension methods for easier usage
extension ReferenceCodeExtensions on String {
  bool get isValidReferenceCode =>
      ReferenceCodeGenerator.validateReferenceCode(this);
  String get referenceDescription =>
      ReferenceCodeGenerator.getReferenceDescription(this);
}

/// Example usage class
class ReferenceCodeExamples {
  static void demonstrateUsage() {
    print('=== Reference Code Generation Examples ===\n');

    // Simple reference
    print('Simple: ${ReferenceCodeGenerator.generateSimpleReference()}');

    // Structured reference
    print(
        'Structured: ${ReferenceCodeGenerator.generateStructuredReference()}');

    // Numeric reference
    print('Numeric: ${ReferenceCodeGenerator.generateNumericReference()}');

    // Timestamp reference
    print('Timestamp: ${ReferenceCodeGenerator.generateTimestampReference()}');

    // UUID-like reference
    print('UUID-like: ${ReferenceCodeGenerator.generateUUIDLikeReference()}');

    // Hash-based reference
    print(
        'Hash-based: ${ReferenceCodeGenerator.generateHashReference(schoolId: "school123")}');

    // Mobile money style
    print(
        'Mobile Money: ${ReferenceCodeGenerator.generateMobileMoneyReference()}');

    // Custom pattern
    print(
        'Custom (XXX-999-XXX): ${ReferenceCodeGenerator.generateCustomPattern("XXX-999-XXX")}');

    // Bank style
    print(
        'Bank Style: ${ReferenceCodeGenerator.generateBankStyleReference(sequentialNumber: 1234)}');

    print('\n=== Validation Examples ===');
    final testCode = ReferenceCodeGenerator.generateStructuredReference();
    print('Code: $testCode');
    print('Valid: ${testCode.isValidReferenceCode}');
    print('Description: ${testCode.referenceDescription}');
  }
}
