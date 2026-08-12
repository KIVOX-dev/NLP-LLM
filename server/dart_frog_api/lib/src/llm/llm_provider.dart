/// Context assembled by the orchestrator before calling the LLM: the
/// linguistic evidence gathered so far, so the model grounds its output in
/// it instead of inventing meanings (spec §3, §12, §20).
class LlmTranslationContext {
  const LlmTranslationContext({
    required this.sanskritText,
    required this.targetLanguageCodes,
    this.dictionaryHits = const [],
    this.retrievedSentences = const [],
    this.tokenizedWords = const [],
    this.sandhiCandidates = const [],
    this.generationBrief,
  });

  final String sanskritText;
  final List<String> targetLanguageCodes;

  /// When set, `generateTrainingExample` invents a brand-new sentence from
  /// this brief instead of reformatting `sanskritText` (which is unused —
  /// pass '' — in that mode). Used by scripts/generate_dataset.dart; the
  /// live API never sets this.
  final DatasetGenerationBrief? generationBrief;

  /// Dictionary entries found for words/lemmas in the sentence, serialized
  /// as plain maps so this stays independent of the repository layer.
  final List<Map<String, dynamic>> dictionaryHits;

  /// Similar previously-verified sentences from vector retrieval.
  final List<Map<String, dynamic>> retrievedSentences;

  final List<String> tokenizedWords;

  final List<Map<String, dynamic>> sandhiCandidates;
}

/// A brief for inventing a new example sentence, rather than analyzing an
/// existing one — see `LlmTranslationContext.generationBrief`.
class DatasetGenerationBrief {
  const DatasetGenerationBrief({required this.category, required this.domain, required this.guidance});

  final String category;
  final String domain;
  final String guidance;
}

class LlmResult {
  const LlmResult({required this.json, this.modelUsed, this.rawText, this.usage});

  /// Parsed structured JSON output (already schema-validated by the caller).
  final Map<String, dynamic> json;
  final String? modelUsed;
  final String? rawText;
  final Map<String, int>? usage;
}

/// Abstraction over any LLM backend. Provider-specific code (auth headers,
/// request/response shape) must live only in the concrete implementation —
/// never leak into the orchestrator or routes (spec §18).
abstract class LLMProvider {
  /// Produces the full structured translation payload described in the
  /// master system prompt (spec §20): source/iast/english/tamil/literal_*/
  /// word_analysis/grammar/sandhi/compounds/pronunciation/confidence/uncertainties.
  Future<LlmResult> translate(LlmTranslationContext context);

  /// Deeper linguistic analysis for `/api/v1/analyze` (morphology + sandhi +
  /// compounds only, no translation).
  Future<LlmResult> analyze(LlmTranslationContext context);

  /// Natural-language grammar explanation (used by the expandable "Grammar"
  /// panel / future grammar-tutor mode).
  Future<String> explainGrammar(LlmTranslationContext context);

  /// Generates a candidate training example from a verified translation,
  /// for future fine-tuning data (spec §18, §27). Output must be marked
  /// synthetic/unverified by the caller — this method only generates text.
  Future<LlmResult> generateTrainingExample(LlmTranslationContext context);
}
