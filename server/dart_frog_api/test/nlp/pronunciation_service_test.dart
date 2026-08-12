import 'package:dart_frog_api/src/nlp/pronunciation_service.dart';
import 'package:test/test.dart';

void main() {
  final service = PronunciationService();

  group('PronunciationService', () {
    test('syllabifies gacchati as gac-cha-ti (spec §21 example)', () {
      final result = service.analyze('गच्छति');
      expect(result.iast, equals('gacchati'));
      expect(result.guide, equals('gac-cha-ti'));
    });

    test('works directly on IAST input', () {
      final result = service.analyze('rāmaḥ');
      expect(result.iast, equals('rāmaḥ'));
      expect(result.guide, equals('rā-maḥ'));
    });

    test('syllabifies a simple two-syllable word', () {
      final result = service.analyze('वनं');
      expect(result.iast, equals('vanaṃ'));
      expect(result.guide, equals('va-naṃ'));
    });
  });
}
