import 'package:dart_frog_api/src/llm/llm_exceptions.dart';
import 'package:dart_frog_api/src/llm/llm_provider.dart';
import 'package:dart_frog_api/src/llm/openai_provider.dart';

/// Wraps one [OpenAIProvider] per API key and rotates on rate-limit (spec
/// request: "use a fallback mechanism when generating 5000 questions so
/// that it doesn't hit limit, use a free tier model").
///
/// Behavior: on a 429/401/403 from the current key, move to the next one
/// immediately (no delay — a different key's limit is independent). Only
/// once *every* key in the pool has been rate-limited in the same pass does
/// it actually wait (exponential backoff, capped), then start the cycle
/// again. This maximizes throughput across the pool while still backing off
/// instead of hammering OpenRouter when the whole pool is genuinely spent.
class RotatingLlmProvider implements LLMProvider {
  RotatingLlmProvider(List<String> apiKeys, {void Function(String message)? onEvent})
      : assert(apiKeys.isNotEmpty, 'RotatingLlmProvider needs at least one API key'),
        _providers = apiKeys.map((key) => OpenAIProvider(apiKey: key)).toList(),
        _onEvent = onEvent ?? ((_) {});

  final List<OpenAIProvider> _providers;
  final void Function(String) _onEvent;

  int _currentIndex = 0;
  int _consecutiveBackoffRounds = 0;

  static const _maxBackoff = Duration(minutes: 5);
  static const _baseBackoff = Duration(seconds: 15);

  @override
  Future<LlmResult> translate(LlmTranslationContext context) =>
      _withRotation((p) => p.translate(context));

  @override
  Future<LlmResult> analyze(LlmTranslationContext context) => _withRotation((p) => p.analyze(context));

  @override
  Future<String> explainGrammar(LlmTranslationContext context) =>
      _withRotation((p) => p.explainGrammar(context));

  @override
  Future<LlmResult> generateTrainingExample(LlmTranslationContext context) =>
      _withRotation((p) => p.generateTrainingExample(context));

  @override
  Future<LlmResult> classifyWord(String word, {Map<String, dynamic>? dictionaryHit}) =>
      _withRotation((p) => p.classifyWord(word, dictionaryHit: dictionaryHit));

  Future<T> _withRotation<T>(Future<T> Function(LLMProvider provider) call) async {
    var attemptsThisPass = 0;

    while (true) {
      final provider = _providers[_currentIndex];
      try {
        final result = await call(provider);
        _consecutiveBackoffRounds = 0;
        return result;
      } on LlmRateLimitedException catch (e) {
        _onEvent('key #$_currentIndex rate-limited (HTTP ${e.statusCode}), trying next key');
        _currentIndex = (_currentIndex + 1) % _providers.length;
        attemptsThisPass++;

        if (attemptsThisPass >= _providers.length) {
          attemptsThisPass = 0;
          _consecutiveBackoffRounds++;
          final backoff = _backoffFor(_consecutiveBackoffRounds);
          _onEvent(
            'all ${_providers.length} keys rate-limited this pass, '
            'backing off ${backoff.inSeconds}s before retrying',
          );
          await Future<void>.delayed(backoff);
        }
      }
    }
  }

  Duration _backoffFor(int round) {
    final seconds = _baseBackoff.inSeconds * (1 << (round - 1).clamp(0, 4));
    final capped = Duration(seconds: seconds).compareTo(_maxBackoff) > 0 ? _maxBackoff : Duration(seconds: seconds);
    return capped;
  }
}
