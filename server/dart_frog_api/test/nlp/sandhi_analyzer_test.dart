import 'package:dart_frog_api/src/nlp/sandhi_analyzer.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  final analyzer = RuleBasedSandhiAnalyzer();

  group('RuleBasedSandhiAnalyzer', () {
    test('splits रामोऽस्ति into रामः + अस्ति (spec §14 example)', () {
      final results = analyzer.analyzeSentence('रामोऽस्ति');

      expect(results, hasLength(1));
      expect(results.first.surface, equals('रामोऽस्ति'));
      expect(results.first.components, equals(['रामः', 'अस्ति']));
      expect(results.first.type, equals(SandhiType.visarga));
      expect(results.first.isAmbiguous, isFalse);
    });

    test('returns no results for text with no sandhi markers', () {
      expect(analyzer.analyzeSentence('रामः वनं गच्छति।'), isEmpty);
    });
  });
}
