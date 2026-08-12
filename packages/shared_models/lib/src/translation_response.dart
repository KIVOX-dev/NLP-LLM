import 'confidence.dart';
import 'grammar_analysis.dart';
import 'word_analysis.dart';

class TranslationSource {
  const TranslationSource({required this.language, required this.original, this.iast});

  final String language;
  final String original;
  final String? iast;

  factory TranslationSource.fromJson(Map<String, dynamic> json) => TranslationSource(
        language: json['language'] as String? ?? 'sa',
        original: json['original'] as String? ?? '',
        iast: json['iast'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'original': original,
        if (iast != null) 'iast': iast,
      };
}

class TranslationMetadata {
  const TranslationMetadata({
    this.modelVersion,
    this.promptVersion,
    this.retrievalVersion,
    this.latencyMs,
    this.sanskritTradition,
  });

  final String? modelVersion;
  final String? promptVersion;
  final String? retrievalVersion;
  final int? latencyMs;

  /// "classical" or "vedic" — never assumed silently; null when undetermined.
  final String? sanskritTradition;

  factory TranslationMetadata.fromJson(Map<String, dynamic> json) => TranslationMetadata(
        modelVersion: json['model_version'] as String?,
        promptVersion: json['prompt_version'] as String?,
        retrievalVersion: json['retrieval_version'] as String?,
        latencyMs: json['latency_ms'] as int?,
        sanskritTradition: json['sanskrit_tradition'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (modelVersion != null) 'model_version': modelVersion,
        if (promptVersion != null) 'prompt_version': promptVersion,
        if (retrievalVersion != null) 'retrieval_version': retrievalVersion,
        if (latencyMs != null) 'latency_ms': latencyMs,
        if (sanskritTradition != null) 'sanskrit_tradition': sanskritTradition,
      };
}

/// Response body for `POST /api/v1/translate`. Mirrors spec §10 exactly so
/// the Flutter UI can render each labeled section directly from this object.
class TranslationResponse {
  const TranslationResponse({
    required this.requestId,
    required this.source,
    required this.translations,
    this.literalTranslation = const {},
    this.words = const [],
    this.grammar,
    this.sandhi = const [],
    this.compounds = const [],
    this.pronunciation,
    this.confidence,
    this.uncertainties = const [],
    this.metadata,
  });

  final String requestId;
  final TranslationSource source;

  /// Keyed by target language code: {"en": "...", "ta": "..."}
  final Map<String, String> translations;

  /// Word-for-word literal rendering, same keying as [translations].
  final Map<String, String> literalTranslation;

  final List<WordAnalysis> words;
  final GrammarAnalysis? grammar;
  final List<SandhiResult> sandhi;
  final List<CompoundResult> compounds;
  final PronunciationResult? pronunciation;
  final Confidence? confidence;

  /// Free-text notes on ambiguity/uncertainty the model or pipeline flagged.
  final List<String> uncertainties;

  final TranslationMetadata? metadata;

  factory TranslationResponse.fromJson(Map<String, dynamic> json) => TranslationResponse(
        requestId: json['request_id'] as String? ?? '',
        source: TranslationSource.fromJson(json['source'] as Map<String, dynamic>? ?? const {}),
        translations: Map<String, String>.from(json['translations'] as Map? ?? const {}),
        literalTranslation:
            Map<String, String>.from(json['literal_translation'] as Map? ?? const {}),
        words: (json['words'] as List<dynamic>?)
                ?.map((e) => WordAnalysis.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        grammar:
            json['grammar'] == null ? null : GrammarAnalysis.fromJson(json['grammar'] as Map<String, dynamic>),
        sandhi: (json['sandhi'] as List<dynamic>?)
                ?.map((e) => SandhiResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        compounds: (json['compounds'] as List<dynamic>?)
                ?.map((e) => CompoundResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        pronunciation: json['pronunciation'] == null
            ? null
            : PronunciationResult.fromJson(json['pronunciation'] as Map<String, dynamic>),
        confidence:
            json['confidence'] == null ? null : Confidence.fromJson(json['confidence'] as Map<String, dynamic>),
        uncertainties:
            (json['uncertainties'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        metadata: json['metadata'] == null
            ? null
            : TranslationMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'source': source.toJson(),
        'translations': translations,
        'literal_translation': literalTranslation,
        'words': words.map((w) => w.toJson()).toList(),
        'grammar': grammar?.toJson(),
        'sandhi': sandhi.map((s) => s.toJson()).toList(),
        'compounds': compounds.map((c) => c.toJson()).toList(),
        'pronunciation': pronunciation?.toJson(),
        'confidence': confidence?.toJson(),
        'uncertainties': uncertainties,
        'metadata': metadata?.toJson(),
      };
}
