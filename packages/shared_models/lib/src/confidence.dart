enum ConfidenceLevel { high, medium, low }

ConfidenceLevel confidenceLevelFromString(String value) {
  switch (value) {
    case 'high':
      return ConfidenceLevel.high;
    case 'medium':
      return ConfidenceLevel.medium;
    case 'low':
    default:
      return ConfidenceLevel.low;
  }
}

/// Application-level confidence assessment. This is deliberately NOT the raw
/// confidence/logprob reported by the LLM — it's computed from lexical match
/// quality, morphological certainty, retrieval quality, and cross-target
/// consistency. See `ConfidenceCalculator` on the server.
class Confidence {
  const Confidence({
    required this.level,
    this.notes = const [],
    this.lexicalMatchScore,
    this.morphologyScore,
    this.retrievalScore,
    this.consistencyScore,
  });

  final ConfidenceLevel level;
  final List<String> notes;

  /// Component scores in [0, 1], null when that signal was unavailable.
  final double? lexicalMatchScore;
  final double? morphologyScore;
  final double? retrievalScore;
  final double? consistencyScore;

  factory Confidence.fromJson(Map<String, dynamic> json) => Confidence(
        level: confidenceLevelFromString(json['level'] as String? ?? 'low'),
        notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        lexicalMatchScore: (json['lexical_match_score'] as num?)?.toDouble(),
        morphologyScore: (json['morphology_score'] as num?)?.toDouble(),
        retrievalScore: (json['retrieval_score'] as num?)?.toDouble(),
        consistencyScore: (json['consistency_score'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'notes': notes,
        if (lexicalMatchScore != null) 'lexical_match_score': lexicalMatchScore,
        if (morphologyScore != null) 'morphology_score': morphologyScore,
        if (retrievalScore != null) 'retrieval_score': retrievalScore,
        if (consistencyScore != null) 'consistency_score': consistencyScore,
      };
}
