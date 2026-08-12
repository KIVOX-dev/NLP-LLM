/// Language codes the platform currently understands as translation targets.
enum TargetLanguage {
  english('en'),
  tamil('ta');

  const TargetLanguage(this.code);

  final String code;

  static TargetLanguage fromCode(String code) {
    return TargetLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => throw ArgumentError.value(code, 'code', 'Unknown target language'),
    );
  }
}

/// Request body for `POST /api/v1/translate`.
class TranslationRequest {
  const TranslationRequest({
    required this.text,
    this.sourceLanguage = 'sa',
    this.targets = const [TargetLanguage.english, TargetLanguage.tamil],
    this.includeWordAnalysis = true,
    this.includeGrammar = true,
    this.includePronunciation = true,
    this.includeSandhi = true,
    this.includeCompounds = true,
    this.conversationId,
  });

  /// Raw Sanskrit input, Devanagari or IAST.
  final String text;

  /// Source language code. Only `sa` (Sanskrit) is currently supported.
  final String sourceLanguage;

  final List<TargetLanguage> targets;

  final bool includeWordAnalysis;
  final bool includeGrammar;
  final bool includePronunciation;
  final bool includeSandhi;
  final bool includeCompounds;

  /// Optional: attach this translation to an existing conversation.
  final String? conversationId;

  factory TranslationRequest.fromJson(Map<String, dynamic> json) {
    final rawTargets = json['targets'] as List<dynamic>?;
    return TranslationRequest(
      text: json['text'] as String? ?? '',
      sourceLanguage: json['source_language'] as String? ?? 'sa',
      targets: rawTargets == null
          ? const [TargetLanguage.english, TargetLanguage.tamil]
          : rawTargets.map((e) => TargetLanguage.fromCode(e as String)).toList(),
      includeWordAnalysis: json['include_word_analysis'] as bool? ?? true,
      includeGrammar: json['include_grammar'] as bool? ?? true,
      includePronunciation: json['include_pronunciation'] as bool? ?? true,
      includeSandhi: json['include_sandhi'] as bool? ?? true,
      includeCompounds: json['include_compounds'] as bool? ?? true,
      conversationId: json['conversation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'source_language': sourceLanguage,
        'targets': targets.map((t) => t.code).toList(),
        'include_word_analysis': includeWordAnalysis,
        'include_grammar': includeGrammar,
        'include_pronunciation': includePronunciation,
        'include_sandhi': includeSandhi,
        'include_compounds': includeCompounds,
        if (conversationId != null) 'conversation_id': conversationId,
      };

  /// Validation errors, empty when the request is well-formed.
  /// Kept here (rather than only on the server) so the Flutter app can
  /// short-circuit obviously invalid input before it hits the network.
  List<String> validate({int maxLength = 2000}) {
    final errors = <String>[];
    if (text.trim().isEmpty) {
      errors.add('text must not be empty');
    }
    if (text.length > maxLength) {
      errors.add('text exceeds maximum length of $maxLength characters');
    }
    if (sourceLanguage != 'sa') {
      errors.add('source_language must be "sa"');
    }
    if (targets.isEmpty) {
      errors.add('targets must contain at least one language');
    }
    return errors;
  }
}
