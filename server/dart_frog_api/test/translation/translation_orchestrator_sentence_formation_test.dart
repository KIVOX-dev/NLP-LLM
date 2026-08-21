import 'package:dart_frog_api/src/llm/llm_provider.dart';
import 'package:dart_frog_api/src/nlp/morphology_analyzer.dart';
import 'package:dart_frog_api/src/nlp/pronunciation_service.dart';
import 'package:dart_frog_api/src/nlp/samasa_analyzer.dart';
import 'package:dart_frog_api/src/nlp/sandhi_analyzer.dart';
import 'package:dart_frog_api/src/repositories/vocabulary_repository.dart';
import 'package:dart_frog_api/src/translation/translation_orchestrator.dart';
import 'package:dart_frog_api/src/vector/vector_search_service.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

class _EmptyVocabularyRepository implements VocabularyRepository {
  @override
  Future<VocabularyEntry?> findByLemma(String lemma) async => null;

  @override
  Future<VocabularyEntry?> findBySurfaceForm(String surface) async => null;

  @override
  Future<List<VocabularyEntry>> search(String query, {int limit = 20}) async => [];
}

/// Records what text the "translate" step actually received, so tests can
/// assert the orchestrator swapped a bare word for a formed sentence before
/// running the rest of the pipeline.
class _FakeLLMProvider implements LLMProvider {
  String? lastTranslateSanskritText;
  String? lastFormationWord;

  @override
  Future<LlmResult> generateExampleSentence(String word, {Map<String, dynamic>? dictionaryHit}) async {
    lastFormationWord = word;
    return LlmResult(json: {'sentence': 'गजः वनं गच्छति।'});
  }

  @override
  Future<LlmResult> translate(LlmTranslationContext context) async {
    lastTranslateSanskritText = context.sanskritText;
    return LlmResult(json: {
      'source': context.sanskritText,
      'english': 'The elephant goes to the forest.',
      'tamil': 'யானை காட்டிற்குச் செல்கிறது.',
    });
  }

  @override
  Future<LlmResult> analyze(LlmTranslationContext context) => throw UnimplementedError();

  @override
  Future<String> explainGrammar(LlmTranslationContext context) => throw UnimplementedError();

  @override
  Future<LlmResult> generateTrainingExample(LlmTranslationContext context) => throw UnimplementedError();
}

void main() {
  group('TranslationOrchestrator sentence formation', () {
    late _FakeLLMProvider llm;
    late TranslationOrchestrator orchestrator;

    setUp(() {
      llm = _FakeLLMProvider();
      orchestrator = TranslationOrchestrator(
        vocabularyRepository: _EmptyVocabularyRepository(),
        morphologyAnalyzer: DictionaryBackedMorphologyAnalyzer(_EmptyVocabularyRepository()),
        sandhiAnalyzer: RuleBasedSandhiAnalyzer(),
        samasaAnalyzer: const UnknownSamasaAnalyzer(),
        pronunciationService: PronunciationService(),
        vectorSearchService: const NoOpVectorSearchService(),
        llmProvider: llm,
      );
    });

    test('a bare single word is expanded into a formed sentence before translating', () async {
      final response = await orchestrator.translate(
        const TranslationRequest(text: 'गजः'),
        requestId: 'req-1',
      );

      expect(llm.lastFormationWord, 'गजः');
      expect(llm.lastTranslateSanskritText, 'गजः वनं गच्छति।');
      expect(response.source.original, 'गजः वनं गच्छति।');
      expect(response.translations['en'], 'The elephant goes to the forest.');
    });

    test('an actual sentence is translated as-is, with no sentence formation call', () async {
      final response = await orchestrator.translate(
        const TranslationRequest(text: 'गजः वनं गच्छति।'),
        requestId: 'req-2',
      );

      expect(llm.lastFormationWord, isNull);
      expect(llm.lastTranslateSanskritText, 'गजः वनं गच्छति।');
      expect(response.source.original, 'गजः वनं गच्छति।');
    });

    test('a single word with trailing daṇḍa still triggers sentence formation, punctuation stripped', () async {
      await orchestrator.translate(const TranslationRequest(text: 'गजः।'), requestId: 'req-3');

      expect(llm.lastFormationWord, 'गजः');
    });
  });
}
