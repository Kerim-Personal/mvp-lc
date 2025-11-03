// test/services/translation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:vocachat/services/translation_service.dart';

void main() {
  group('TranslationService Quote Preservation', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService.instance;
    });

    test('extractQuotedText extracts single quoted text', () {
      final input = "This is 'must' and 'should' example.";
      final result = service.extractQuotedText(input);
      final processedText = result['processedText'] as String;
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should have 2 placeholders
      expect(quotedTexts.length, 2);
      
      // Processed text should contain placeholders
      expect(processedText.contains('___QUOTE_0___'), true);
      expect(processedText.contains('___QUOTE_1___'), true);
      
      // Original quoted text should be preserved with quotes
      expect(quotedTexts.values.contains("'must'"), true);
      expect(quotedTexts.values.contains("'should'"), true);
    });

    test('extractQuotedText extracts double quoted text', () {
      final input = 'The word "hello" and "world" are common.';
      final result = service.extractQuotedText(input);
      final processedText = result['processedText'] as String;
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should have 2 placeholders
      expect(quotedTexts.length, 2);
      
      // Processed text should contain placeholders
      expect(processedText.contains('___QUOTE_0___'), true);
      expect(processedText.contains('___QUOTE_1___'), true);
      
      // Original quoted text should be preserved with quotes
      expect(quotedTexts.values.contains('"hello"'), true);
      expect(quotedTexts.values.contains('"world"'), true);
    });

    test('extractQuotedText handles mixed single and double quotes', () {
      final input = "The 'modal' word and \"auxiliary\" verb.";
      final result = service.extractQuotedText(input);
      final processedText = result['processedText'] as String;
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should have 2 placeholders
      expect(quotedTexts.length, 2);
      
      // Original quoted text should be preserved with their respective quotes
      expect(quotedTexts.values.contains("'modal'"), true);
      expect(quotedTexts.values.contains('"auxiliary"'), true);
    });

    test('extractQuotedText handles empty quotes', () {
      final input = "Empty quotes '' and \"\" here.";
      final result = service.extractQuotedText(input);
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should extract empty quoted strings
      expect(quotedTexts.length, 2);
      expect(quotedTexts.values.contains("''"), true);
      expect(quotedTexts.values.contains('""'), true);
    });

    test('extractQuotedText handles text with no quotes', () {
      final input = "This has no quoted text.";
      final result = service.extractQuotedText(input);
      final processedText = result['processedText'] as String;
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should have no placeholders
      expect(quotedTexts.length, 0);
      
      // Processed text should be unchanged
      expect(processedText, input);
    });

    test('extractQuotedText handles multiple quotes of same type', () {
      final input = "'must' shows certainty, 'may' shows possibility, 'can't' shows impossibility.";
      final result = service.extractQuotedText(input);
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should have 3 placeholders
      expect(quotedTexts.length, 3);
      expect(quotedTexts.values.contains("'must'"), true);
      expect(quotedTexts.values.contains("'may'"), true);
      expect(quotedTexts.values.contains("'can't'"), true);
    });

    test('restoreQuotedText restores placeholders correctly', () {
      final translatedText = "This is ___QUOTE_0___ and ___QUOTE_1___ example.";
      final quotedTexts = {
        '___QUOTE_0___': "'must'",
        '___QUOTE_1___': "'should'",
      };
      
      final result = service.restoreQuotedText(translatedText, quotedTexts);
      
      expect(result, "This is 'must' and 'should' example.");
    });

    test('restoreQuotedText handles empty quoted texts map', () {
      final translatedText = "This has no placeholders.";
      final quotedTexts = <String, String>{};
      
      final result = service.restoreQuotedText(translatedText, quotedTexts);
      
      expect(result, translatedText);
    });

    test('Round trip: extract and restore preserves original structure', () {
      final original = "Modals 'must', 'may', and \"can't\" are important.";
      
      // Extract
      final extractResult = service.extractQuotedText(original);
      final processedText = extractResult['processedText'] as String;
      final quotedTexts = extractResult['quotedTexts'] as Map<String, String>;
      
      // Verify placeholders are in processed text
      expect(processedText.contains('___QUOTE_'), true);
      expect(processedText.contains("'must'"), false);
      expect(processedText.contains("'may'"), false);
      expect(processedText.contains('"can\'t"'), false);
      
      // Restore
      final restored = service.restoreQuotedText(processedText, quotedTexts);
      
      // Should match original
      expect(restored, original);
    });

    test('Handles educational content example from lessons', () {
      final content = "Modals of deduction are used to make logical conclusions. 'Must' shows strong certainty, 'may/might/could' show possibility, and 'can't' shows impossibility.";
      
      final extractResult = service.extractQuotedText(content);
      final processedText = extractResult['processedText'] as String;
      final quotedTexts = extractResult['quotedTexts'] as Map<String, String>;
      
      // Should extract 3 quoted parts
      expect(quotedTexts.length, 3);
      expect(quotedTexts.values.contains("'Must'"), true);
      expect(quotedTexts.values.contains("'may/might/could'"), true);
      expect(quotedTexts.values.contains("'can't'"), true);
      
      // Processed text should not contain the quoted originals
      expect(processedText.contains("'Must'"), false);
      expect(processedText.contains("'may/might/could'"), false);
      expect(processedText.contains("'can't'"), false);
    });

    test('Handles apostrophes within contractions (edge case)', () {
      final input = "The word \"don't\" is a contraction.";
      final result = service.extractQuotedText(input);
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      // Should only extract double-quoted text, not the apostrophe
      expect(quotedTexts.length, 1);
      expect(quotedTexts.values.contains('"don\'t"'), true);
    });

    test('Handles quoted text at start and end of string', () {
      final input = "'Start' some middle text 'end'";
      final result = service.extractQuotedText(input);
      final quotedTexts = result['quotedTexts'] as Map<String, String>;

      expect(quotedTexts.length, 2);
      expect(quotedTexts.values.contains("'Start'"), true);
      expect(quotedTexts.values.contains("'end'"), true);
    });
  });
}
