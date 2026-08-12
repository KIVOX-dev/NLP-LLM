/// Splits Sanskrit text into sentences and surface-form word tokens.
///
/// This is a deterministic, whitespace/daṇḍa-based tokenizer — Sanskrit has
/// no spaces between sandhi-joined words within a token, so "words" here are
/// pre-sandhi surface forms, not necessarily final lemmas. Sandhi splitting
/// happens separately in [SandhiAnalyzer].
class SanskritTokenizer {
  const SanskritTokenizer();

  static final _sentenceSplit = RegExp(r'(?<=[।॥.!?])\s+');
  static final _wordSplit = RegExp(r'\s+');
  static final _punctuationTrim = RegExp(r'^[।॥.,!?;:"‘’“”()\[\]]+|[।॥.,!?;:"‘’“”()\[\]]+$');

  List<String> splitSentences(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(_sentenceSplit)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> tokenizeWords(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return const [];
    return normalized
        .split(_wordSplit)
        .map((w) => w.replaceAll(_punctuationTrim, '').trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }
}
