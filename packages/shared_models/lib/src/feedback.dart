enum FeedbackRating { up, down }

FeedbackRating feedbackRatingFromString(String value) =>
    value == 'down' ? FeedbackRating.down : FeedbackRating.up;

/// POST /api/v1/feedback body. Either a simple thumbs rating, or a full
/// correction (original + incorrect + correct). See spec §29.
class TranslationFeedback {
  const TranslationFeedback({
    required this.translationId,
    this.modelVersion,
    this.promptVersion,
    this.retrievalVersion,
    this.rating,
    this.language,
    this.originalText,
    this.incorrectTranslation,
    this.correctTranslation,
    this.comment,
  });

  final String translationId;
  final String? modelVersion;
  final String? promptVersion;
  final String? retrievalVersion;
  final FeedbackRating? rating;

  final String? language;
  final String? originalText;
  final String? incorrectTranslation;
  final String? correctTranslation;
  final String? comment;

  factory TranslationFeedback.fromJson(Map<String, dynamic> json) => TranslationFeedback(
        translationId: json['translation_id'] as String? ?? '',
        modelVersion: json['model_version'] as String?,
        promptVersion: json['prompt_version'] as String?,
        retrievalVersion: json['retrieval_version'] as String?,
        rating: json['rating'] == null ? null : feedbackRatingFromString(json['rating'] as String),
        language: json['language'] as String?,
        originalText: json['original'] as String?,
        incorrectTranslation: json['incorrect_translation'] as String?,
        correctTranslation: json['correct_translation'] as String?,
        comment: json['comment'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'translation_id': translationId,
        if (modelVersion != null) 'model_version': modelVersion,
        if (promptVersion != null) 'prompt_version': promptVersion,
        if (retrievalVersion != null) 'retrieval_version': retrievalVersion,
        if (rating != null) 'rating': rating!.name,
        if (language != null) 'language': language,
        if (originalText != null) 'original': originalText,
        if (incorrectTranslation != null) 'incorrect_translation': incorrectTranslation,
        if (correctTranslation != null) 'correct_translation': correctTranslation,
        if (comment != null) 'comment': comment,
      };

  List<String> validate() {
    final errors = <String>[];
    if (translationId.trim().isEmpty) errors.add('translation_id is required');
    final hasRating = rating != null;
    final hasCorrection = correctTranslation != null && correctTranslation!.trim().isNotEmpty;
    if (!hasRating && !hasCorrection) {
      errors.add('either rating or correct_translation must be provided');
    }
    return errors;
  }
}
