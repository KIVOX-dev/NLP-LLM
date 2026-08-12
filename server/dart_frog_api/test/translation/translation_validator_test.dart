import 'package:dart_frog_api/src/translation/translation_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = TranslationValidator();

  group('TranslationValidator', () {
    test('accepts a well-formed payload', () {
      final problems = validator.validate({
        'source': 'रामः वनं गच्छति।',
        'english': 'Rama goes to the forest.',
        'tamil': 'ராமன் காட்டிற்குச் செல்கிறான்.',
        'word_analysis': [
          {'surface': 'रामः'},
        ],
        'grammar': {'subject': 'रामः'},
        'pronunciation': {'original': 'रामः'},
        'confidence': {'level': 'high'},
      });

      expect(problems, isEmpty);
    });

    test('flags missing required fields', () {
      final problems = validator.validate({'source': 'रामः'});
      expect(problems, contains('missing or empty required field "english"'));
      expect(problems, contains('missing or empty required field "tamil"'));
    });

    test('flags wrong types for object/array fields', () {
      final problems = validator.validate({
        'source': 'x',
        'english': 'y',
        'tamil': 'z',
        'grammar': 'not an object',
        'word_analysis': 'not a list',
      });

      expect(problems, contains('field "grammar" must be an object when present'));
      expect(problems, contains('field "word_analysis" must be an array when present'));
    });

    test('isValid mirrors validate', () {
      expect(validator.isValid({'source': 'x', 'english': 'y', 'tamil': 'z'}), isTrue);
      expect(validator.isValid({}), isFalse);
    });
  });
}
