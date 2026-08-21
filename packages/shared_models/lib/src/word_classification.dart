/// Coarse semantic category for a single Sanskrit word — the four buckets
/// from the classic "Name, Place, Animal, Thing" word game, used by
/// `POST /api/v1/word-classify`.
enum WordCategory {
  name('name'),
  place('place'),
  animal('animal'),
  thing('thing');

  const WordCategory(this.value);

  final String value;

  static WordCategory fromJson(String? value) => WordCategory.values.firstWhere(
        (c) => c.value == value,
        orElse: () => WordCategory.thing,
      );
}

/// Request body for `POST /api/v1/word-classify`.
class WordClassificationRequest {
  const WordClassificationRequest({required this.word});

  /// A single Sanskrit word, Devanagari or IAST.
  final String word;

  factory WordClassificationRequest.fromJson(Map<String, dynamic> json) =>
      WordClassificationRequest(word: json['word'] as String? ?? '');

  Map<String, dynamic> toJson() => {'word': word};

  /// Validation errors, empty when the request is well-formed. Kept here
  /// (rather than only on the server) so the Flutter app can short-circuit
  /// obviously invalid input before it hits the network.
  List<String> validate({int maxLength = 100}) {
    final trimmed = word.trim();
    final errors = <String>[];
    if (trimmed.isEmpty) {
      errors.add('word must not be empty');
    } else if (trimmed.contains(RegExp(r'\s'))) {
      errors.add('word must be a single word, not a phrase or sentence');
    }
    if (word.length > maxLength) {
      errors.add('word exceeds maximum length of $maxLength characters');
    }
    return errors;
  }
}

/// Response body for `POST /api/v1/word-classify`.
class WordClassificationResponse {
  const WordClassificationResponse({
    required this.word,
    required this.iast,
    required this.category,
    required this.englishMeaning,
    required this.exampleSanskrit,
    required this.exampleEnglish,
    this.confidence,
  });

  final String word;
  final String iast;
  final WordCategory category;
  final String englishMeaning;

  /// A short Sanskrit sentence that uses [word].
  final String exampleSanskrit;

  /// English translation of [exampleSanskrit].
  final String exampleEnglish;

  final String? confidence;

  factory WordClassificationResponse.fromJson(Map<String, dynamic> json) => WordClassificationResponse(
        word: json['word'] as String? ?? '',
        iast: json['iast'] as String? ?? '',
        category: WordCategory.fromJson(json['category'] as String?),
        englishMeaning: json['english_meaning'] as String? ?? '',
        exampleSanskrit: json['example_sanskrit'] as String? ?? '',
        exampleEnglish: json['example_english'] as String? ?? '',
        confidence: json['confidence'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'iast': iast,
        'category': category.value,
        'english_meaning': englishMeaning,
        'example_sanskrit': exampleSanskrit,
        'example_english': exampleEnglish,
        if (confidence != null) 'confidence': confidence,
      };
}
