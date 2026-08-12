import 'package:shared_models/shared_models.dart';

import 'iast_transliterator.dart';

enum _PhonemeType { vowel, consonant, marker, other }

class _Phoneme {
  const _Phoneme(this.type, this.text);
  final _PhonemeType type;
  final String text;
}

/// Produces a syllabified pronunciation guide from Sanskrit text.
///
/// This is a deterministic CV-syllabification over the IAST rendering, not a
/// claim about phonetic realization in any specific recitation tradition
/// (spec §21) — it is a general-purpose reading aid.
///
/// Rule used for medial consonant clusters (standard Sanskrit syllabification):
/// given a cluster of consonants between two vowels, all but the last
/// consonant close the preceding syllable, and the last consonant opens the
/// following syllable. E.g. gacchati -> ga + [c,ch] + ti -> "gac" | "cha" | "ti".
class PronunciationService {
  PronunciationService({IastTransliterator transliterator = const IastTransliterator()})
      : _transliterator = transliterator;

  final IastTransliterator _transliterator;

  // Longest-match-first phoneme list.
  static const List<String> _consonantDigraphs = [
    'kh', 'gh', 'ch', 'jh', 'ṭh', 'ḍh', 'th', 'dh', 'ph', 'bh',
  ];
  static const List<String> _consonantSingles = [
    'k', 'g', 'ṅ', 'c', 'j', 'ñ', 'ṭ', 'ḍ', 'ṇ', 't', 'd', 'n',
    'p', 'b', 'm', 'y', 'r', 'l', 'v', 'ś', 'ṣ', 's', 'h', 'ḷ',
  ];
  static const List<String> _vowelDiphthongs = ['ai', 'au'];
  static const List<String> _vowelSingles = [
    'ā', 'ī', 'ū', 'ṝ', 'ḹ', 'a', 'i', 'u', 'ṛ', 'ḷ', 'e', 'o',
  ];
  static const List<String> _markers = ['ṃ', 'ḥ', 'm̐'];

  PronunciationResult analyze(String original) {
    final iast =
        _transliterator.containsDevanagari(original) ? _transliterator.transliterate(original) : original;
    final syllables = _syllabify(iast);
    return PronunciationResult(
      original: original,
      iast: iast,
      syllables: syllables,
      guide: syllables.join('-'),
    );
  }

  List<_Phoneme> _tokenize(String iastWord) {
    final phonemes = <_Phoneme>[];
    var i = 0;
    final lower = iastWord;
    while (i < lower.length) {
      final match = _matchLongest(lower, i, _markers) ??
          _matchLongest(lower, i, _consonantDigraphs) ??
          _matchLongest(lower, i, _vowelDiphthongs) ??
          _matchLongest(lower, i, _consonantSingles) ??
          _matchLongest(lower, i, _vowelSingles);
      if (match != null) {
        final type = _markers.contains(match)
            ? _PhonemeType.marker
            : (_consonantDigraphs.contains(match) || _consonantSingles.contains(match))
                ? _PhonemeType.consonant
                : _PhonemeType.vowel;
        phonemes.add(_Phoneme(type, match));
        i += match.length;
      } else {
        phonemes.add(_Phoneme(_PhonemeType.other, lower[i]));
        i += 1;
      }
    }
    return phonemes;
  }

  String? _matchLongest(String source, int start, List<String> candidates) {
    for (final candidate in candidates) {
      if (start + candidate.length <= source.length &&
          source.substring(start, start + candidate.length) == candidate) {
        return candidate;
      }
    }
    return null;
  }

  List<String> _syllabify(String iastText) {
    final result = <String>[];
    for (final word in iastText.split(RegExp(r'\s+'))) {
      if (word.trim().isEmpty) continue;
      result.addAll(_syllabifyWord(word));
    }
    return result;
  }

  List<String> _syllabifyWord(String word) {
    final phonemes = _tokenize(word);
    final vowelIndices = <int>[
      for (var i = 0; i < phonemes.length; i++)
        if (phonemes[i].type == _PhonemeType.vowel) i,
    ];

    if (vowelIndices.isEmpty) return [word];

    final syllables = <String>[];
    var pendingOnset = phonemes.sublist(0, vowelIndices.first).map((p) => p.text).join();

    for (var v = 0; v < vowelIndices.length; v++) {
      final vowelIndex = vowelIndices[v];
      final buffer = StringBuffer(pendingOnset)..write(phonemes[vowelIndex].text);
      pendingOnset = '';

      final nextVowelIndex = v + 1 < vowelIndices.length ? vowelIndices[v + 1] : null;
      final clusterEnd = nextVowelIndex ?? phonemes.length;
      final cluster = phonemes.sublist(vowelIndex + 1, clusterEnd);

      if (nextVowelIndex == null) {
        // Trailing consonants/markers: all close the final syllable.
        buffer.write(cluster.map((p) => p.text).join());
      } else if (cluster.isEmpty) {
        // No consonants between vowels — nothing to carry.
      } else {
        // Last consonant becomes the onset of the next syllable; the rest
        // (including any anusvara/visarga marker) close this syllable.
        final lastIsConsonant = cluster.last.type == _PhonemeType.consonant;
        if (lastIsConsonant && cluster.length > 0) {
          buffer.write(cluster.sublist(0, cluster.length - 1).map((p) => p.text).join());
          pendingOnset = cluster.last.text;
        } else {
          buffer.write(cluster.map((p) => p.text).join());
        }
      }

      syllables.add(buffer.toString());
    }

    return syllables;
  }
}
