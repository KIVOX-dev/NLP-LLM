import 'package:shared_models/shared_models.dart';

import '../config/env_config.dart';
import '../core/errors/app_exception.dart';
import '../core/logging/request_logger.dart';
import '../llm/llm_provider.dart';
import '../nlp/iast_transliterator.dart';
import '../nlp/morphology_analyzer.dart';
import '../nlp/pronunciation_service.dart';
import '../nlp/samasa_analyzer.dart';
import '../nlp/sandhi_analyzer.dart';
import '../nlp/sanskrit_tokenizer.dart';
import '../repositories/vocabulary_repository.dart';
import '../vector/vector_search_service.dart';
import 'confidence_calculator.dart';
import 'translation_validator.dart';

/// Implements the pipeline from spec §12, step by step. Linguistic evidence
/// (tokenization, IAST, sandhi, dictionary/morphology, retrieval) is
/// computed *before* the LLM is called and passed to it as grounding
/// context; the LLM's own claims are then merged with — and never allowed
/// to silently override — that deterministic evidence.
class TranslationOrchestrator {
  TranslationOrchestrator({
    required VocabularyRepository vocabularyRepository,
    required SanskritMorphologyAnalyzer morphologyAnalyzer,
    required SandhiAnalyzer sandhiAnalyzer,
    required SamasaAnalyzer samasaAnalyzer,
    required PronunciationService pronunciationService,
    required VectorSearchService vectorSearchService,
    required LLMProvider llmProvider,
    IastTransliterator transliterator = const IastTransliterator(),
    SanskritTokenizer tokenizer = const SanskritTokenizer(),
    TranslationValidator validator = const TranslationValidator(),
    ConfidenceCalculator confidenceCalculator = const ConfidenceCalculator(),
  })  : _vocabularyRepository = vocabularyRepository,
        _morphologyAnalyzer = morphologyAnalyzer,
        _sandhiAnalyzer = sandhiAnalyzer,
        _samasaAnalyzer = samasaAnalyzer,
        _pronunciationService = pronunciationService,
        _vectorSearchService = vectorSearchService,
        _llmProvider = llmProvider,
        _transliterator = transliterator,
        _tokenizer = tokenizer,
        _validator = validator,
        _confidenceCalculator = confidenceCalculator;

  final VocabularyRepository _vocabularyRepository;
  final SanskritMorphologyAnalyzer _morphologyAnalyzer;
  final SandhiAnalyzer _sandhiAnalyzer;
  final SamasaAnalyzer _samasaAnalyzer;
  final PronunciationService _pronunciationService;
  final VectorSearchService _vectorSearchService;
  final LLMProvider _llmProvider;
  final IastTransliterator _transliterator;
  final SanskritTokenizer _tokenizer;
  final TranslationValidator _validator;
  final ConfidenceCalculator _confidenceCalculator;

  Future<TranslationResponse> translate(TranslationRequest request, {required String requestId}) async {
    // 1. Input validation
    final errors = request.validate(maxLength: EnvConfig.instance.maxInputCharacters);
    if (errors.isNotEmpty) {
      throw AppException.validation(errors.join('; '));
    }

    // 2. Unicode normalization
    final normalizedText = _normalize(request.text);

    // 3. Language identification is trusted from the (validated) request —
    // only Sanskrit source is supported today.

    // 4. Tokenization
    final words = _tokenizer.tokenizeWords(normalizedText);

    // 5. IAST normalization
    final iast = _transliterator.transliterate(normalizedText);

    // 6. Sandhi analysis
    final sandhiResults = request.includeSandhi ? _sandhiAnalyzer.analyzeSentence(normalizedText) : <SandhiResult>[];

    // 7-9. Morphological analysis + lemma identification + dictionary lookup
    final groundedWords = <WordAnalysis>[];
    if (request.includeWordAnalysis) {
      for (final word in words) {
        groundedWords.add(await _analyzeWord(word));
      }
    }

    // Compounds (samāsa) — currently defers to the LLM; see SamasaAnalyzer.
    final ruleBasedCompounds = request.includeCompounds ? await _samasaAnalyzer.analyzeSentence(normalizedText) : <CompoundResult>[];

    // Pronunciation
    final pronunciation = request.includePronunciation ? _pronunciationService.analyze(normalizedText) : null;

    // 10. Vector retrieval
    final retrievedSentences = await _vectorSearchService.searchSimilarTranslations(normalizedText);

    // 11. Context construction
    final dictionaryHits = groundedWords
        .where((w) => w.sourceName != null)
        .map((w) => {
              'surface': w.surface,
              'english_meaning': w.englishMeaning,
              'tamil_meaning': w.tamilMeaning,
            })
        .toList();

    final llmContext = LlmTranslationContext(
      sanskritText: normalizedText,
      targetLanguageCodes: request.targets.map((t) => t.code).toList(),
      dictionaryHits: dictionaryHits,
      retrievedSentences: retrievedSentences,
      tokenizedWords: words,
      sandhiCandidates: sandhiResults.map((s) => s.toJson()).toList(),
    );

    // 12. LLM request
    final llmResult = await _llmProvider.translate(llmContext);

    // 13. JSON schema validation
    final problems = _validator.validate(llmResult.json);
    if (problems.isNotEmpty) {
      RequestLogger.error(
        'translation.invalid_llm_output',
        requestId: requestId,
        errorCode: 'SCHEMA_INVALID',
        fields: {'problems': problems},
      );
      throw AppException.translationFailed('Translation could not be completed.');
    }

    final json = llmResult.json;

    final finalWords = request.includeWordAnalysis
        ? _mergeWordAnalyses(groundedWords, (json['word_analysis'] as List<dynamic>?) ?? const [])
        : <WordAnalysis>[];

    final grammar = request.includeGrammar && json['grammar'] is Map
        ? GrammarAnalysis.fromJson(json['grammar'] as Map<String, dynamic>)
        : null;

    final finalSandhi =
        request.includeSandhi ? _mergeSandhi(sandhiResults, (json['sandhi'] as List<dynamic>?) ?? const []) : <SandhiResult>[];

    final finalCompounds = request.includeCompounds
        ? [
            ...ruleBasedCompounds,
            ...((json['compounds'] as List<dynamic>?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(CompoundResult.fromJson),
          ]
        : <CompoundResult>[];

    final translations = <String, String>{};
    final literal = <String, String>{};
    for (final target in request.targets) {
      if (target == TargetLanguage.english) {
        translations['en'] = json['english'] as String? ?? '';
        literal['en'] = json['literal_english'] as String? ?? '';
      } else if (target == TargetLanguage.tamil) {
        translations['ta'] = json['tamil'] as String? ?? '';
        literal['ta'] = json['literal_tamil'] as String? ?? '';
      }
    }

    final uncertainties =
        ((json['uncertainties'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList();

    // 14-15. Consistency check + confidence calculation
    final confidence = _confidenceCalculator.calculate(
      words: finalWords,
      retrievalHitCount: retrievedSentences.length,
      fluentEnglish: translations['en'] ?? '',
      literalEnglish: literal['en'] ?? '',
      llmUncertainties: uncertainties,
    );

    // 16. Final response
    return TranslationResponse(
      requestId: requestId,
      source: TranslationSource(language: 'sa', original: normalizedText, iast: iast),
      translations: translations,
      literalTranslation: literal,
      words: finalWords,
      grammar: grammar,
      sandhi: finalSandhi,
      compounds: finalCompounds,
      pronunciation: pronunciation,
      confidence: confidence,
      uncertainties: uncertainties,
      metadata: TranslationMetadata(
        modelVersion: llmResult.modelUsed,
        sanskritTradition: json['sanskrit_tradition'] as String?,
      ),
    );
  }

  Future<WordAnalysis> _analyzeWord(String word) async {
    final dictEntry =
        await _vocabularyRepository.findBySurfaceForm(word) ?? await _vocabularyRepository.findByLemma(word);
    final morphology = await _morphologyAnalyzer.analyzeWord(word);

    return WordAnalysis(
      surface: word,
      iast: _transliterator.transliterate(word),
      englishMeaning: dictEntry != null && dictEntry.englishMeanings.isNotEmpty ? dictEntry.englishMeanings.first : null,
      tamilMeaning: dictEntry != null && dictEntry.tamilMeanings.isNotEmpty ? dictEntry.tamilMeanings.first : null,
      morphology: morphology,
      sourceName: dictEntry?.sourceName ?? dictEntry?.id,
      verified: dictEntry?.verified ?? false,
    );
  }

  String _normalize(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Grounded (dictionary/morphology-backed) results win; the LLM's
  /// word_analysis only fills in fields our deterministic pipeline left null
  /// (e.g. an English/Tamil gloss when no dictionary entry existed).
  List<WordAnalysis> _mergeWordAnalyses(List<WordAnalysis> grounded, List<dynamic> llmWords) {
    final llmMaps = llmWords.whereType<Map<String, dynamic>>().toList();
    if (grounded.isEmpty) {
      return llmMaps.map(WordAnalysis.fromJson).toList();
    }

    final llmBySurface = {for (final w in llmMaps) (w['surface'] as String? ?? ''): w};

    return grounded.map((word) {
      final llmMatch = llmBySurface[word.surface];
      if (llmMatch == null) return word;

      final llmMorphologyMap = llmMatch['morphology'];
      final useLlmMorphology =
          (word.morphology == null || word.morphology!.partOfSpeech == PartOfSpeech.unknown) &&
              llmMorphologyMap is Map<String, dynamic>;

      return WordAnalysis(
        surface: word.surface,
        iast: word.iast.isNotEmpty ? word.iast : (llmMatch['iast'] as String? ?? ''),
        englishMeaning: word.englishMeaning ?? llmMatch['english_meaning'] as String?,
        tamilMeaning: word.tamilMeaning ?? llmMatch['tamil_meaning'] as String?,
        morphology: useLlmMorphology ? WordMorphology.fromJson(llmMorphologyMap) : word.morphology,
        sourceName: word.sourceName,
        verified: word.verified,
      );
    }).toList();
  }

  /// Deterministic rule-based sandhi results are authoritative; LLM-proposed
  /// splits are only added for surfaces the rule-based analyzer didn't cover.
  List<SandhiResult> _mergeSandhi(List<SandhiResult> ruleBased, List<dynamic> llmSandhi) {
    final llmResults =
        llmSandhi.whereType<Map<String, dynamic>>().map(SandhiResult.fromJson).toList();
    final ruleSurfaces = ruleBased.map((s) => s.surface).toSet();
    return [
      ...ruleBased,
      ...llmResults.where((r) => !ruleSurfaces.contains(r.surface)),
    ];
  }
}
