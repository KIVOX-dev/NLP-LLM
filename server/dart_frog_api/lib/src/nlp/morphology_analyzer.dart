import 'package:shared_models/shared_models.dart';

import '../repositories/vocabulary_repository.dart';

/// Grounds morphology in the dictionary rather than guessing. This is
/// intentionally conservative: without a real inflectional-suffix engine
/// (future work — see docs/BUILD_PHASES.md), it can only report what the
/// dictionary entry itself states (part of speech, gender for nouns) plus
/// the surface/lemma relationship. Case, tense, person, etc. are left null
/// here and are expected to come from the LLM (grounded on this evidence),
/// which is explicitly told to mark low confidence when unsure (spec §13,
/// §20). This class must never fabricate a case/tense ending.
abstract class SanskritMorphologyAnalyzer {
  Future<WordMorphology> analyzeWord(String surface);
}

class DictionaryBackedMorphologyAnalyzer implements SanskritMorphologyAnalyzer {
  DictionaryBackedMorphologyAnalyzer(this._vocabulary);

  final VocabularyRepository _vocabulary;

  @override
  Future<WordMorphology> analyzeWord(String surface) async {
    final entry = await _vocabulary.findBySurfaceForm(surface) ?? await _vocabulary.findByLemma(surface);

    if (entry == null) {
      return const WordMorphology(
        partOfSpeech: PartOfSpeech.unknown,
        confidence: ConfidenceLevel.low,
      );
    }

    return WordMorphology(
      partOfSpeech: partOfSpeechFromString(entry.pos),
      lemma: entry.lemma,
      gender: entry.gender,
      // Case/number/tense require inflection analysis beyond a dictionary
      // lookup; left null rather than guessed.
      confidence: ConfidenceLevel.medium,
    );
  }
}
