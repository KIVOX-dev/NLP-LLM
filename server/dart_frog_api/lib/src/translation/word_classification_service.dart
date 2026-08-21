import 'package:shared_models/shared_models.dart';

import '../core/errors/app_exception.dart';
import '../llm/llm_provider.dart';
import '../repositories/vocabulary_repository.dart';

/// Orchestrates `POST /api/v1/word-classify`: look up dictionary evidence
/// for the word (grounding, same spirit as [TranslationOrchestrator]), call
/// the LLM to classify it and produce an example sentence, then validate the
/// shape of what came back.
class WordClassificationService {
  WordClassificationService({
    required VocabularyRepository vocabularyRepository,
    required LLMProvider llmProvider,
  })  : _vocabularyRepository = vocabularyRepository,
        _llmProvider = llmProvider;

  final VocabularyRepository _vocabularyRepository;
  final LLMProvider _llmProvider;

  static const _requiredStringFields = ['word', 'category', 'example_sanskrit', 'example_english'];
  static const _validCategories = {'name', 'place', 'animal', 'thing'};

  Future<WordClassificationResponse> classify(String rawWord) async {
    final word = rawWord.trim();

    final dictEntry =
        await _vocabularyRepository.findBySurfaceForm(word) ?? await _vocabularyRepository.findByLemma(word);
    final dictionaryHit = dictEntry == null
        ? null
        : {
            'lemma': dictEntry.lemma,
            'iast': dictEntry.iast,
            'pos': dictEntry.pos,
            'english_meanings': dictEntry.englishMeanings,
            'domains': dictEntry.domains,
          };

    final result = await _llmProvider.classifyWord(word, dictionaryHit: dictionaryHit);
    final json = result.json;

    final problems = _validate(json);
    if (problems.isNotEmpty) {
      throw AppException.translationFailed('The classification engine returned an invalid response.');
    }

    return WordClassificationResponse.fromJson(json);
  }

  List<String> _validate(Map<String, dynamic> json) {
    final problems = <String>[];
    for (final field in _requiredStringFields) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        problems.add('missing or empty required field "$field"');
      }
    }
    final category = json['category'];
    if (category is String && !_validCategories.contains(category)) {
      problems.add('field "category" must be one of $_validCategories');
    }
    return problems;
  }
}
