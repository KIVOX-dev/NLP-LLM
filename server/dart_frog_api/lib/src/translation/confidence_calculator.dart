import 'package:shared_models/shared_models.dart';

/// Computes an application-level confidence assessment. This intentionally
/// does not read any "confidence" the LLM claims for itself — that number is
/// not calibrated (spec §50). Instead it's derived from signals the pipeline
/// itself can measure: how many words had dictionary evidence, how many had
/// resolved morphology, whether retrieval returned anything, and whether the
/// literal and fluent translations broadly agree in length/word-overlap.
class ConfidenceCalculator {
  const ConfidenceCalculator();

  Confidence calculate({
    required List<WordAnalysis> words,
    required int retrievalHitCount,
    required String fluentEnglish,
    required String literalEnglish,
    List<String> llmUncertainties = const [],
  }) {
    final notes = <String>[];

    double? lexicalMatchScore;
    double? morphologyScore;
    if (words.isNotEmpty) {
      final withDictionaryEvidence = words.where((w) => w.sourceName != null).length;
      lexicalMatchScore = withDictionaryEvidence / words.length;

      final withKnownMorphology =
          words.where((w) => w.morphology != null && w.morphology!.confidence != ConfidenceLevel.low).length;
      morphologyScore = withKnownMorphology / words.length;
    }

    final retrievalScore = retrievalHitCount > 0 ? 1.0 : 0.0;
    if (retrievalHitCount == 0) {
      notes.add('No similar verified sentences were retrieved for this input.');
    }

    double? consistencyScore;
    if (fluentEnglish.isNotEmpty && literalEnglish.isNotEmpty) {
      final fluentWords = fluentEnglish.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toSet();
      final literalWords =
          literalEnglish.toLowerCase().split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toSet();
      if (fluentWords.isNotEmpty && literalWords.isNotEmpty) {
        final overlap = fluentWords.intersection(literalWords).length;
        consistencyScore = overlap / fluentWords.length.clamp(1, 1 << 30);
        if (consistencyScore < 0.15) {
          notes.add('Fluent and literal translations share little vocabulary overlap; review recommended.');
        }
      }
    }

    if (llmUncertainties.isNotEmpty) {
      notes.addAll(llmUncertainties);
    }

    final scores = [lexicalMatchScore, morphologyScore, retrievalScore, consistencyScore]
        .whereType<double>()
        .toList();
    final average = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    final level = llmUncertainties.isNotEmpty && average < 0.6
        ? ConfidenceLevel.low
        : average >= 0.66
            ? ConfidenceLevel.high
            : average >= 0.4
                ? ConfidenceLevel.medium
                : ConfidenceLevel.low;

    return Confidence(
      level: level,
      notes: notes,
      lexicalMatchScore: lexicalMatchScore,
      morphologyScore: morphologyScore,
      retrievalScore: retrievalScore,
      consistencyScore: consistencyScore,
    );
  }
}
