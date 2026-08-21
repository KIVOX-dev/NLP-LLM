import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/llm/llm_provider.dart';
import 'package:dart_frog_api/src/repositories/vocabulary_repository.dart';
import 'package:dart_frog_api/src/translation/word_classification_service.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

class _FakeVocabularyRepository implements VocabularyRepository {
  _FakeVocabularyRepository({this.entry});

  final VocabularyEntry? entry;

  @override
  Future<VocabularyEntry?> findByLemma(String lemma) async => entry;

  @override
  Future<VocabularyEntry?> findBySurfaceForm(String surface) async => entry;

  @override
  Future<List<VocabularyEntry>> search(String query, {int limit = 20}) async => entry == null ? [] : [entry!];
}

class _FakeLLMProvider implements LLMProvider {
  _FakeLLMProvider(this.classifyResult);

  final Map<String, dynamic> classifyResult;
  Map<String, dynamic>? lastDictionaryHit;

  @override
  Future<LlmResult> classifyWord(String word, {Map<String, dynamic>? dictionaryHit}) async {
    lastDictionaryHit = dictionaryHit;
    return LlmResult(json: classifyResult);
  }

  @override
  Future<LlmResult> analyze(LlmTranslationContext context) => throw UnimplementedError();

  @override
  Future<String> explainGrammar(LlmTranslationContext context) => throw UnimplementedError();

  @override
  Future<LlmResult> generateTrainingExample(LlmTranslationContext context) => throw UnimplementedError();

  @override
  Future<LlmResult> translate(LlmTranslationContext context) => throw UnimplementedError();
}

void main() {
  group('WordClassificationService', () {
    test('returns a parsed classification for a well-formed LLM response', () async {
      final llm = _FakeLLMProvider({
        'word': 'गजः',
        'iast': 'gajaḥ',
        'category': 'animal',
        'english_meaning': 'elephant',
        'example_sanskrit': 'गजः वनं गच्छति।',
        'example_english': 'The elephant goes to the forest.',
        'confidence': 'high',
      });
      final service = WordClassificationService(
        vocabularyRepository: _FakeVocabularyRepository(),
        llmProvider: llm,
      );

      final result = await service.classify('गजः');

      expect(result.category.value, 'animal');
      expect(result.exampleSanskrit, isNotEmpty);
      expect(result.exampleEnglish, isNotEmpty);
    });

    test('passes dictionary evidence through to the LLM when a dictionary entry exists', () async {
      final llm = _FakeLLMProvider({
        'word': 'धर्मः',
        'category': 'thing',
        'example_sanskrit': 'धर्मः रक्षति।',
        'example_english': 'Dharma protects.',
      });
      final entry = VocabularyEntry(
        id: '1',
        lemma: 'धर्म',
        iast: 'dharma',
        englishMeanings: const ['duty', 'righteousness'],
      );
      final service = WordClassificationService(
        vocabularyRepository: _FakeVocabularyRepository(entry: entry),
        llmProvider: llm,
      );

      await service.classify('धर्मः');

      expect(llm.lastDictionaryHit, isNotNull);
      expect(llm.lastDictionaryHit!['lemma'], 'धर्म');
    });

    test('throws AppException.translationFailed when the LLM response is missing required fields', () async {
      final llm = _FakeLLMProvider({'word': 'गजः'});
      final service = WordClassificationService(
        vocabularyRepository: _FakeVocabularyRepository(),
        llmProvider: llm,
      );

      expect(
        () => service.classify('गजः'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', ApiErrorCode.translationFailed)),
      );
    });

    test('throws AppException.translationFailed when category is not one of the four buckets', () async {
      final llm = _FakeLLMProvider({
        'word': 'गजः',
        'category': 'verb',
        'example_sanskrit': 'x',
        'example_english': 'y',
      });
      final service = WordClassificationService(
        vocabularyRepository: _FakeVocabularyRepository(),
        llmProvider: llm,
      );

      expect(() => service.classify('गजः'), throwsA(isA<AppException>()));
    });
  });
}
