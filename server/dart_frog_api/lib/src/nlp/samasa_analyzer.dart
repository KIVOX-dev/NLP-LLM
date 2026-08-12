import 'package:shared_models/shared_models.dart';

/// Compound (samāsa) classifier interface (spec §15). No reliable rule-based
/// classifier exists yet — classifying tatpuruṣa vs. bahuvrīhi etc. requires
/// semantic judgment, not just orthography. Rather than guess, the current
/// implementation always reports `unknown` and defers to the LLM, which is
/// instructed not to force a classification either. Replacing this with a
/// real classifier (dictionary + heuristics, or a trained model) is an
/// open extension point.
abstract class SamasaAnalyzer {
  Future<List<CompoundResult>> analyzeSentence(String sentence);
}

class UnknownSamasaAnalyzer implements SamasaAnalyzer {
  const UnknownSamasaAnalyzer();

  @override
  Future<List<CompoundResult>> analyzeSentence(String sentence) async => const [];
}
