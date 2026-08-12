import 'package:shared_models/shared_models.dart';

import 'sanskrit_tokenizer.dart';

/// Rule-based (non-LLM) sandhi splitter. Deliberately narrow: it only
/// reports a split when a deterministic orthographic rule applies, and
/// never guesses a segmentation it cannot justify (spec §14 — "must
/// preserve uncertainty where multiple segmentations are possible").
///
/// Currently implemented:
///   - avagraha (ऽ) elision: X-o + ऽ + Y  =>  X-aḥ + a + Y
///     e.g. रामोऽस्ति  =>  रामः + अस्ति
///
/// Everything else is left to the LLM (which is told, via the system
/// prompt, that these rule-based candidates are partial) or surfaced as an
/// unresolved ambiguity rather than a fabricated split.
abstract class SandhiAnalyzer {
  List<SandhiResult> analyzeSentence(String sentence);
}

class RuleBasedSandhiAnalyzer implements SandhiAnalyzer {
  RuleBasedSandhiAnalyzer({SanskritTokenizer tokenizer = const SanskritTokenizer()})
      : _tokenizer = tokenizer;

  final SanskritTokenizer _tokenizer;

  static const int _avagraha = 0x093D; // ऽ
  static const int _oMatra = 0x094B; // ो
  static const int _visarga = 0x0903; // ः
  static const int _a = 0x0905; // अ

  @override
  List<SandhiResult> analyzeSentence(String sentence) {
    final results = <SandhiResult>[];
    for (final word in _tokenizer.tokenizeWords(sentence)) {
      final avagrahaSplit = _splitOnAvagraha(word);
      if (avagrahaSplit != null) results.add(avagrahaSplit);
    }
    return results;
  }

  SandhiResult? _splitOnAvagraha(String word) {
    final runes = word.runes.toList();
    final avagrahaIndex = runes.indexOf(_avagraha);
    if (avagrahaIndex <= 0) return null; // no avagraha, or nothing before it

    final charBefore = runes[avagrahaIndex - 1];
    if (charBefore != _oMatra) {
      // Avagraha present but not preceded by the o-matra we know how to
      // reverse; report the surface form as ambiguous instead of guessing.
      return SandhiResult(
        surface: word,
        components: const [],
        type: SandhiType.vowel,
        isAmbiguous: true,
        rule: 'avagraha present; reversal pattern not recognized',
      );
    }

    final before = String.fromCharCodes(runes.sublist(0, avagrahaIndex - 1));
    final after = String.fromCharCodes(runes.sublist(avagrahaIndex + 1));

    final firstComponent = before + String.fromCharCode(_visarga);
    final secondComponent = String.fromCharCode(_a) + after;

    return SandhiResult(
      surface: word,
      components: [firstComponent, secondComponent],
      type: SandhiType.visarga,
      rule: 'aḥ + a → o + ‘ (avagraha elision of word-initial a after visarga sandhi)',
      isAmbiguous: false,
    );
  }
}
