import 'package:dart_frog_api/src/nlp/iast_transliterator.dart';
import 'package:test/test.dart';

void main() {
  final transliterator = IastTransliterator();

  group('IastTransliterator', () {
    test('transliterates the sample sentence from the spec', () {
      expect(
        transliterator.transliterate('रामः वनं गच्छति।'),
        equals('rāmaḥ vanaṃ gacchati.'),
      );
    });

    test('handles independent vowels', () {
      expect(transliterator.transliterate('अ आ इ ई उ ऊ ऋ ए ऐ ओ औ'),
          equals('a ā i ī u ū ṛ e ai o au'));
    });

    test('suppresses inherent vowel before virama', () {
      expect(transliterator.transliterate('तत्'), equals('tat'));
    });

    test('applies matras instead of inherent vowel', () {
      expect(transliterator.transliterate('गीता'), equals('gītā'));
    });

    test('passes through non-Devanagari text unchanged', () {
      expect(transliterator.transliterate('hello'), equals('hello'));
    });

    test('containsDevanagari detects Devanagari script', () {
      expect(transliterator.containsDevanagari('रामः'), isTrue);
      expect(transliterator.containsDevanagari('rāmaḥ'), isFalse);
    });
  });
}
