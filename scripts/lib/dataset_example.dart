/// One row of the training dataset (spec §23). JSONL-serializable.
class DatasetExample {
  const DatasetExample({
    required this.id,
    required this.sanskrit,
    required this.iast,
    required this.english,
    required this.tamil,
    required this.words,
    required this.grammar,
    required this.sandhi,
    required this.compounds,
    required this.domain,
    required this.difficulty,
    required this.sourceType,
    required this.verified,
    this.literalEnglish,
    this.literalTamil,
    this.pronunciation = const {},
    this.confidence = const {},
    this.uncertainties = const [],
    this.sanskritTradition = 'unknown',
  });

  final String id;
  final String sanskrit;
  final String iast;
  final String english;
  final String tamil;
  final List<Map<String, dynamic>> words;
  final Map<String, dynamic> grammar;
  final List<Map<String, dynamic>> sandhi;
  final List<Map<String, dynamic>> compounds;
  final String domain;
  final String difficulty;
  final String sourceType;
  final bool verified;

  // These four mirror fields the production LLM contract (kTranslationSystemPrompt
  // in server/dart_frog_api/lib/src/llm/prompts.dart) requires in every real
  // response. They're captured here too so that if this dataset is ever used
  // for fine-tuning, the training examples teach the model to actually
  // produce them — training data whose assistant turns are missing fields the
  // real API always returns would teach the wrong response shape.
  final String? literalEnglish;
  final String? literalTamil;
  final Map<String, dynamic> pronunciation;
  final Map<String, dynamic> confidence;
  final List<String> uncertainties;
  final String sanskritTradition;

  factory DatasetExample.fromJson(Map<String, dynamic> json) => DatasetExample(
        id: json['id'] as String,
        sanskrit: json['sanskrit'] as String,
        iast: json['iast'] as String,
        english: json['english'] as String,
        tamil: json['tamil'] as String,
        words: (json['words'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
        grammar: (json['grammar'] as Map<String, dynamic>?) ?? const {},
        sandhi: (json['sandhi'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
        compounds: (json['compounds'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
        domain: json['domain'] as String? ?? 'general',
        difficulty: json['difficulty'] as String? ?? 'medium',
        sourceType: json['source_type'] as String? ?? 'synthetic',
        verified: json['verified'] as bool? ?? false,
        literalEnglish: json['literal_english'] as String?,
        literalTamil: json['literal_tamil'] as String?,
        pronunciation: (json['pronunciation'] as Map<String, dynamic>?) ?? const {},
        confidence: (json['confidence'] as Map<String, dynamic>?) ?? const {},
        uncertainties: (json['uncertainties'] as List<dynamic>? ?? const []).cast<String>(),
        sanskritTradition: json['sanskrit_tradition'] as String? ?? 'unknown',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sanskrit': sanskrit,
        'iast': iast,
        'english': english,
        'tamil': tamil,
        'literal_english': literalEnglish,
        'literal_tamil': literalTamil,
        'words': words,
        'grammar': grammar,
        'sandhi': sandhi,
        'compounds': compounds,
        'pronunciation': pronunciation,
        'confidence': confidence,
        'uncertainties': uncertainties,
        'sanskrit_tradition': sanskritTradition,
        'domain': domain,
        'difficulty': difficulty,
        'source_type': sourceType,
        'verified': verified,
      };
}

/// One category from the distribution table in spec §24.
class DatasetCategory {
  const DatasetCategory(this.name, this.targetCount, this.domain, this.guidance);

  final String name;
  final int targetCount;
  final String domain;

  /// Short instruction appended to the generation prompt so the model
  /// actually produces varied sentences for this category instead of
  /// template spam (spec §24: "Do not create repetitive template spam").
  final String guidance;
}

/// Mirrors spec §24 exactly (total 5,000). `create_embeddings.dart` and
/// `generate_dataset.dart` both read this so the distribution only lives in
/// one place.
const List<DatasetCategory> datasetDistribution = [
  DatasetCategory('basic_vocabulary', 500, 'general',
      'Simple single-clause sentences introducing common everyday nouns and adjectives.'),
  DatasetCategory('nouns', 400, 'grammar', 'Sentences that vary noun declension: case, gender, and number.'),
  DatasetCategory('pronouns', 200, 'grammar', 'Sentences built around personal, demonstrative, and relative pronouns.'),
  DatasetCategory('verbs', 700, 'grammar', 'Sentences varying verb root, tense, and voice across common dhātus.'),
  DatasetCategory('adjectives', 300, 'grammar', 'Sentences where an adjective agrees with a noun in case/number/gender.'),
  DatasetCategory('adverbs', 150, 'grammar', 'Sentences using indeclinable adverbs of manner, place, or time.'),
  DatasetCategory('cases', 400, 'grammar', 'Sentences that each foreground a different one of the seven cases (vibhakti).'),
  DatasetCategory('tenses', 400, 'grammar', 'The same or similar action expressed across present, past, and future tenses.'),
  DatasetCategory('participles', 200, 'grammar', 'Sentences using present/past participles (kṛdanta forms).'),
  DatasetCategory('sandhi', 300, 'phonology', 'Sentences chosen specifically because they contain vowel, consonant, or visarga sandhi at word boundaries.'),
  DatasetCategory('compounds', 250, 'morphology', 'Sentences containing a samāsa (tatpuruṣa, karmadhāraya, bahuvrīhi, dvandva, or avyayībhāva).'),
  DatasetCategory('questions', 200, 'conversation', 'Interrogative sentences.'),
  DatasetCategory('negation', 150, 'grammar', 'Sentences using negation (na / mā).'),
  DatasetCategory('commands', 150, 'grammar', 'Imperative-mood sentences (loṭ lakāra).'),
  DatasetCategory('conversation', 200, 'conversation', 'Short conversational exchanges appropriate for a learner.'),
  DatasetCategory('classical_prose', 300, 'literature', 'Classical-prose-style sentences in the register of narrative Sanskrit texts.'),
  DatasetCategory('philosophical_vocabulary', 250, 'philosophy',
      'Sentences using core philosophical/ethical vocabulary (dharma, ātman, karma, mokṣa, etc.) in ordinary, non-quoted usage.'),
  DatasetCategory('numbers_time_dates', 100, 'general', 'Sentences involving numbers, time expressions, or dates.'),
  DatasetCategory('tamil_variation', 100, 'general',
      'Sentences chosen because their Tamil translation has a genuinely distinct natural phrasing from a literal rendering.'),
  DatasetCategory('difficult_evaluation', 100, 'evaluation',
      'Deliberately hard cases: rare vocabulary, ambiguous word sense, or unusual word order. Mark difficulty as "hard".'),
];

int get datasetDistributionTotal => datasetDistribution.fold(0, (sum, c) => sum + c.targetCount);
