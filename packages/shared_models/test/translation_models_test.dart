import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('TranslationRequest', () {
    test('validate() rejects empty text', () {
      const request = TranslationRequest(text: '');
      expect(request.validate(), contains('text must not be empty'));
    });

    test('validate() rejects text over the max length', () {
      final request = TranslationRequest(text: 'क' * 10);
      expect(request.validate(maxLength: 5), isNotEmpty);
    });

    test('validate() accepts a well-formed request', () {
      const request = TranslationRequest(text: 'रामः वनं गच्छति।');
      expect(request.validate(), isEmpty);
    });

    test('round-trips through JSON', () {
      const request = TranslationRequest(
        text: 'रामः वनं गच्छति।',
        targets: [TargetLanguage.english],
      );
      final decoded = TranslationRequest.fromJson(request.toJson());
      expect(decoded.text, equals(request.text));
      expect(decoded.targets, equals(request.targets));
    });
  });

  group('TranslationResponse', () {
    test('round-trips through JSON', () {
      const response = TranslationResponse(
        requestId: 'abc-123',
        source: TranslationSource(language: 'sa', original: 'रामः वनं गच्छति।', iast: 'rāmaḥ vanaṃ gacchati.'),
        translations: {'en': 'Rama goes to the forest.', 'ta': 'ராமன் காட்டிற்குச் செல்கிறான்.'},
        confidence: Confidence(level: ConfidenceLevel.high),
      );

      final decoded = TranslationResponse.fromJson(response.toJson());
      expect(decoded.requestId, equals('abc-123'));
      expect(decoded.translations['en'], equals('Rama goes to the forest.'));
      expect(decoded.confidence?.level, equals(ConfidenceLevel.high));
    });
  });

  group('TranslationFeedback', () {
    test('validate() requires either a rating or a correction', () {
      const feedback = TranslationFeedback(translationId: 't1');
      expect(feedback.validate(), isNotEmpty);
    });

    test('validate() accepts a rating alone', () {
      const feedback = TranslationFeedback(translationId: 't1', rating: FeedbackRating.up);
      expect(feedback.validate(), isEmpty);
    });
  });
}
