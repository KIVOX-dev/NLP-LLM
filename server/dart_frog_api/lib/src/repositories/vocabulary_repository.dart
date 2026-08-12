/// A dictionary record as stored in `sanskrit_words` (spec §16).
class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.lemma,
    required this.iast,
    this.surfaceForms = const [],
    this.pos,
    this.gender,
    this.englishMeanings = const [],
    this.tamilMeanings = const [],
    this.domains = const [],
    this.sourceName,
    this.sourceType,
    this.verified = false,
  });

  final String id;
  final String lemma;
  final String iast;
  final List<String> surfaceForms;
  final String? pos;
  final String? gender;
  final List<String> englishMeanings;
  final List<String> tamilMeanings;
  final List<String> domains;
  final String? sourceName;
  final String? sourceType;
  final bool verified;

  factory VocabularyEntry.fromMap(Map<String, dynamic> map) => VocabularyEntry(
        id: map['_id'].toString(),
        lemma: map['lemma'] as String? ?? '',
        iast: map['iast'] as String? ?? '',
        surfaceForms: (map['surface_forms'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pos: map['pos'] as String?,
        gender: map['gender'] as String?,
        englishMeanings:
            (map['english_meanings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tamilMeanings: (map['tamil_meanings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        domains: (map['domains'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        sourceName: map['source_name'] as String?,
        sourceType: map['source_type'] as String?,
        verified: map['verified'] as bool? ?? false,
      );
}

/// Abstraction over the Sanskrit dictionary so the translation pipeline and
/// tests don't depend on MongoDB directly.
abstract class VocabularyRepository {
  /// Exact lemma or IAST lookup (used for morphology/word-analysis grounding).
  Future<VocabularyEntry?> findByLemma(String lemma);

  /// Looks up a raw surface form (pre-sandhi word as it appears in text).
  Future<VocabularyEntry?> findBySurfaceForm(String surface);

  /// Free-text search across lemma/iast/surface/English/Tamil meanings.
  Future<List<VocabularyEntry>> search(String query, {int limit = 20});
}
