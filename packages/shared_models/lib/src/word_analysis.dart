import 'confidence.dart';

enum PartOfSpeech {
  noun,
  pronoun,
  adjective,
  verb,
  participle,
  indeclinable,
  compound,
  properNoun,
  unknown,
}

PartOfSpeech partOfSpeechFromString(String? value) {
  switch (value) {
    case 'noun':
      return PartOfSpeech.noun;
    case 'pronoun':
      return PartOfSpeech.pronoun;
    case 'adjective':
      return PartOfSpeech.adjective;
    case 'verb':
      return PartOfSpeech.verb;
    case 'participle':
      return PartOfSpeech.participle;
    case 'indeclinable':
      return PartOfSpeech.indeclinable;
    case 'compound':
      return PartOfSpeech.compound;
    case 'proper_noun':
      return PartOfSpeech.properNoun;
    default:
      return PartOfSpeech.unknown;
  }
}

String partOfSpeechToString(PartOfSpeech pos) {
  if (pos == PartOfSpeech.properNoun) return 'proper_noun';
  return pos.name;
}

/// Morphological analysis for a single word. Every field is nullable because
/// not every field applies to every part of speech, and the analyzer must be
/// able to report "unknown" instead of guessing.
///
/// See `SanskritMorphologyAnalyzer` on the server: this must never be filled
/// in with a hallucinated guess — if the analyzer is not confident, leave the
/// field null and let `confidence` reflect it.
class WordMorphology {
  const WordMorphology({
    required this.partOfSpeech,
    this.lemma,
    this.root,
    this.gender,
    this.number,
    this.grammaticalCase,
    this.declension,
    this.syntacticRole,
    this.person,
    this.tense,
    this.mood,
    this.voice,
    this.lakara,
    this.verbClass,
    this.isCausative = false,
    this.isDesiderative = false,
    this.isIntensive = false,
    this.confidence = ConfidenceLevel.low,
  });

  final PartOfSpeech partOfSpeech;

  // Nominal fields
  final String? lemma;
  final String? gender;
  final String? number;
  final String? grammaticalCase;
  final String? declension;
  final String? syntacticRole;

  // Verbal fields
  final String? root; // dhātu
  final String? person;
  final String? tense;
  final String? mood;
  final String? voice;
  final String? lakara;
  final String? verbClass;
  final bool isCausative;
  final bool isDesiderative;
  final bool isIntensive;

  final ConfidenceLevel confidence;

  factory WordMorphology.fromJson(Map<String, dynamic> json) => WordMorphology(
        partOfSpeech: partOfSpeechFromString(json['part_of_speech'] as String?),
        lemma: json['lemma'] as String?,
        gender: json['gender'] as String?,
        number: json['number'] as String?,
        grammaticalCase: json['case'] as String?,
        declension: json['declension'] as String?,
        syntacticRole: json['syntactic_role'] as String?,
        root: json['root'] as String?,
        person: json['person'] as String?,
        tense: json['tense'] as String?,
        mood: json['mood'] as String?,
        voice: json['voice'] as String?,
        lakara: json['lakara'] as String?,
        verbClass: json['verb_class'] as String?,
        isCausative: json['is_causative'] as bool? ?? false,
        isDesiderative: json['is_desiderative'] as bool? ?? false,
        isIntensive: json['is_intensive'] as bool? ?? false,
        confidence: confidenceLevelFromString(json['confidence'] as String? ?? 'low'),
      );

  Map<String, dynamic> toJson() => {
        'part_of_speech': partOfSpeechToString(partOfSpeech),
        if (lemma != null) 'lemma': lemma,
        if (gender != null) 'gender': gender,
        if (number != null) 'number': number,
        if (grammaticalCase != null) 'case': grammaticalCase,
        if (declension != null) 'declension': declension,
        if (syntacticRole != null) 'syntactic_role': syntacticRole,
        if (root != null) 'root': root,
        if (person != null) 'person': person,
        if (tense != null) 'tense': tense,
        if (mood != null) 'mood': mood,
        if (voice != null) 'voice': voice,
        if (lakara != null) 'lakara': lakara,
        if (verbClass != null) 'verb_class': verbClass,
        'is_causative': isCausative,
        'is_desiderative': isDesiderative,
        'is_intensive': isIntensive,
        'confidence': confidence.name,
      };
}

/// One entry in the word-by-word breakdown shown under the translation.
class WordAnalysis {
  const WordAnalysis({
    required this.surface,
    required this.iast,
    this.englishMeaning,
    this.tamilMeaning,
    this.morphology,
    this.sourceName,
    this.verified = false,
  });

  final String surface;
  final String iast;
  final String? englishMeaning;
  final String? tamilMeaning;
  final WordMorphology? morphology;

  /// Where the meaning came from (dictionary lemma id, corpus, or "llm").
  /// Never fabricated — see rule against inventing citations.
  final String? sourceName;
  final bool verified;

  factory WordAnalysis.fromJson(Map<String, dynamic> json) => WordAnalysis(
        surface: json['surface'] as String? ?? '',
        iast: json['iast'] as String? ?? '',
        englishMeaning: json['english_meaning'] as String?,
        tamilMeaning: json['tamil_meaning'] as String?,
        morphology: json['morphology'] == null
            ? null
            : WordMorphology.fromJson(json['morphology'] as Map<String, dynamic>),
        sourceName: json['source_name'] as String?,
        verified: json['verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'iast': iast,
        if (englishMeaning != null) 'english_meaning': englishMeaning,
        if (tamilMeaning != null) 'tamil_meaning': tamilMeaning,
        if (morphology != null) 'morphology': morphology!.toJson(),
        if (sourceName != null) 'source_name': sourceName,
        'verified': verified,
      };
}
