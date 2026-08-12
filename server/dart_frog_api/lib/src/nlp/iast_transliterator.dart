/// Deterministic Devanagari → IAST transliteration.
///
/// This is real, rule-based transliteration (not an LLM call) — it is the
/// kind of "linguistic evidence" the pipeline must compute itself rather
/// than delegate to the model (spec §3, §12). Unknown/unsupported code
/// points are passed through unchanged rather than dropped, so nothing is
/// silently altered.
class IastTransliterator {
  const IastTransliterator();

  static const Map<int, String> _independentVowels = {
    0x0905: 'a',
    0x0906: 'ā',
    0x0907: 'i',
    0x0908: 'ī',
    0x0909: 'u',
    0x090A: 'ū',
    0x090B: 'ṛ',
    0x0960: 'ṝ',
    0x090C: 'ḷ',
    0x0961: 'ḹ',
    0x090F: 'e',
    0x0910: 'ai',
    0x0913: 'o',
    0x0914: 'au',
    0x090D: 'ê', // candra e (rare)
    0x0911: 'ô', // candra o (rare)
  };

  static const Map<int, String> _matras = {
    0x093E: 'ā',
    0x093F: 'i',
    0x0940: 'ī',
    0x0941: 'u',
    0x0942: 'ū',
    0x0943: 'ṛ',
    0x0944: 'ṝ',
    0x0962: 'ḷ',
    0x0963: 'ḹ',
    0x0947: 'e',
    0x0948: 'ai',
    0x094B: 'o',
    0x094C: 'au',
  };

  static const Map<int, String> _consonants = {
    0x0915: 'k',
    0x0916: 'kh',
    0x0917: 'g',
    0x0918: 'gh',
    0x0919: 'ṅ',
    0x091A: 'c',
    0x091B: 'ch',
    0x091C: 'j',
    0x091D: 'jh',
    0x091E: 'ñ',
    0x091F: 'ṭ',
    0x0920: 'ṭh',
    0x0921: 'ḍ',
    0x0922: 'ḍh',
    0x0923: 'ṇ',
    0x0924: 't',
    0x0925: 'th',
    0x0926: 'd',
    0x0927: 'dh',
    0x0928: 'n',
    0x092A: 'p',
    0x092B: 'ph',
    0x092C: 'b',
    0x092D: 'bh',
    0x092E: 'm',
    0x092F: 'y',
    0x0930: 'r',
    0x0932: 'l',
    0x0933: 'ḷ', // retroflex l (Vedic)
    0x0935: 'v',
    0x0936: 'ś',
    0x0937: 'ṣ',
    0x0938: 's',
    0x0939: 'h',
    0x0958: 'q',
    0x0959: 'khh',
    0x095A: 'ġ',
    0x095B: 'z',
    0x095C: 'ṛh',
    0x095D: 'ṛh',
    0x095E: 'f',
    0x095F: 'yy',
  };

  static const Map<int, String> _digits = {
    0x0966: '0',
    0x0967: '1',
    0x0968: '2',
    0x0969: '3',
    0x096A: '4',
    0x096B: '5',
    0x096C: '6',
    0x096D: '7',
    0x096E: '8',
    0x096F: '9',
  };

  static const int _virama = 0x094D;
  static const int _anusvara = 0x0902;
  static const int _visarga = 0x0903;
  static const int _candrabindu = 0x0901;
  static const int _avagraha = 0x093D;
  static const int _danda = 0x0964;
  static const int _doubleDanda = 0x0965;
  static const int _om = 0x0950;

  bool isConsonant(int codeUnit) => _consonants.containsKey(codeUnit);

  String transliterate(String devanagari) {
    final buffer = StringBuffer();
    final codeUnits = devanagari.runes.toList();

    for (var i = 0; i < codeUnits.length; i++) {
      final cp = codeUnits[i];

      if (_consonants.containsKey(cp)) {
        buffer.write(_consonants[cp]);
        final next = i + 1 < codeUnits.length ? codeUnits[i + 1] : null;
        if (next == _virama) {
          i++; // consonant cluster / word-final: suppress inherent 'a'
        } else if (next != null && _matras.containsKey(next)) {
          buffer.write(_matras[next]);
          i++;
        } else {
          buffer.write('a'); // inherent vowel
        }
        continue;
      }

      if (_independentVowels.containsKey(cp)) {
        buffer.write(_independentVowels[cp]);
        continue;
      }

      if (_digits.containsKey(cp)) {
        buffer.write(_digits[cp]);
        continue;
      }

      switch (cp) {
        case _anusvara:
          buffer.write('ṃ');
        case _visarga:
          buffer.write('ḥ');
        case _candrabindu:
          buffer.write('m̐');
        case _avagraha:
          buffer.write("'");
        case _danda:
          buffer.write('.');
        case _doubleDanda:
          buffer.write('..');
        case _om:
          buffer.write('oṃ');
        default:
          buffer.writeCharCode(cp); // pass through (spaces, ASCII, unknown)
      }
    }

    return buffer.toString();
  }

  /// True if [text] contains any Devanagari code points.
  bool containsDevanagari(String text) => text.runes.any((cp) => cp >= 0x0900 && cp <= 0x097F);
}
