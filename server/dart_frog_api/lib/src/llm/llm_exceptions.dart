/// Thrown specifically for HTTP 429 (and 401/403, which OpenRouter also
/// returns when a particular free-tier key has exhausted its daily quota)
/// so callers that maintain a pool of keys — see `RotatingLlmProvider` in
/// scripts/lib/rotating_llm_provider.dart — can distinguish "this key is
/// spent, try the next one" from a genuine failure worth giving up on.
class LlmRateLimitedException implements Exception {
  const LlmRateLimitedException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'LlmRateLimitedException($statusCode): $message';
}
