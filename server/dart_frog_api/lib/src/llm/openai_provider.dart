import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../core/errors/app_exception.dart';
import 'llm_exceptions.dart';
import 'llm_provider.dart';
import 'prompts.dart';

/// OpenAI implementation of [LLMProvider], using the Chat Completions API
/// with `response_format: {"type": "json_object"}` so the model is
/// constrained to return valid JSON syntax. Our own [TranslationValidator]
/// (see lib/src/translation/translation_validator.dart) still checks the
/// JSON matches the expected shape — `json_object` mode guarantees valid
/// JSON, not our schema.
///
/// Also the provider used against OpenRouter (any OpenAI-compatible
/// endpoint works — see OPENAI_BASE_URL in .env.example) — this class has
/// no OpenAI-specific behavior beyond the request/response shape, which
/// OpenRouter mirrors.
class OpenAIProvider implements LLMProvider {
  OpenAIProvider({
    http.Client? httpClient,
    String? apiKey,
    String? baseUrl,
    String? model,
    Duration? timeout,
  })  : _httpClient = httpClient ?? http.Client(),
        _apiKeyOverride = apiKey,
        _baseUrlOverride = baseUrl,
        _modelOverride = model,
        _timeoutOverride = timeout;

  final http.Client _httpClient;
  final EnvConfig _env = EnvConfig.instance;

  /// Overrides `EnvConfig.openAiApiKey` when set — used by
  /// `RotatingLlmProvider` (scripts/) to run one `OpenAIProvider` per key
  /// in a fallback pool without touching global env state.
  final String? _apiKeyOverride;

  /// Overrides `EnvConfig.openAiBaseUrl`/model — used by
  /// scripts/generate_dataset.dart to point at a local Ollama instance for
  /// bulk generation without touching the live API server's OpenRouter
  /// configuration (they're independent by design).
  final String? _baseUrlOverride;
  final String? _modelOverride;
  final Duration? _timeoutOverride;

  Uri get _endpoint => Uri.parse('${_baseUrlOverride ?? _env.openAiBaseUrl}/chat/completions');

  @override
  Future<LlmResult> translate(LlmTranslationContext context) => _completeJson(
        model: _env.openAiModel,
        systemPrompt: kTranslationSystemPrompt,
        userPrompt: buildTranslationUserPrompt(
          sanskritText: context.sanskritText,
          targetLanguageCodes: context.targetLanguageCodes,
          dictionaryHits: context.dictionaryHits,
          retrievedSentences: context.retrievedSentences,
          tokenizedWords: context.tokenizedWords,
          sandhiCandidates: context.sandhiCandidates,
        ),
      );

  @override
  Future<LlmResult> analyze(LlmTranslationContext context) => _completeJson(
        model: _env.openAiModel,
        systemPrompt: '$kTranslationSystemPrompt\n\n'
            'For this request, focus only on: word_analysis, grammar, sandhi, compounds, '
            'pronunciation. You may leave english/tamil/literal_english/literal_tamil empty strings.',
        userPrompt: buildTranslationUserPrompt(
          sanskritText: context.sanskritText,
          targetLanguageCodes: context.targetLanguageCodes,
          dictionaryHits: context.dictionaryHits,
          retrievedSentences: context.retrievedSentences,
          tokenizedWords: context.tokenizedWords,
          sandhiCandidates: context.sandhiCandidates,
        ),
      );

  @override
  Future<String> explainGrammar(LlmTranslationContext context) async {
    final result = await _completeText(
      model: _env.openAiModel,
      systemPrompt: 'You are a Sanskrit grammar tutor. Explain the grammar of the given '
          'sentence in clear prose for a learner. Ground your explanation only in the '
          'provided evidence; say so explicitly if something is uncertain. Never invent '
          'grammatical facts.',
      userPrompt: buildTranslationUserPrompt(
        sanskritText: context.sanskritText,
        targetLanguageCodes: context.targetLanguageCodes,
        dictionaryHits: context.dictionaryHits,
        retrievedSentences: context.retrievedSentences,
        tokenizedWords: context.tokenizedWords,
        sandhiCandidates: context.sandhiCandidates,
      ),
    );
    return result;
  }

  @override
  Future<LlmResult> generateTrainingExample(LlmTranslationContext context) {
    final brief = context.generationBrief;
    if (brief != null) {
      return _completeJson(
        model: _modelOverride ?? _env.openAiEconomyModel,
        systemPrompt: kDatasetGenerationSystemPrompt,
        userPrompt: buildDatasetGenerationUserPrompt(
          category: brief.category,
          domain: brief.domain,
          guidance: brief.guidance,
        ),
      );
    }
    return _completeJson(
      model: _env.openAiEconomyModel,
      systemPrompt: kTranslationSystemPrompt,
      userPrompt: buildTranslationUserPrompt(
        sanskritText: context.sanskritText,
        targetLanguageCodes: context.targetLanguageCodes,
        dictionaryHits: context.dictionaryHits,
        retrievedSentences: context.retrievedSentences,
        tokenizedWords: context.tokenizedWords,
        sandhiCandidates: context.sandhiCandidates,
      ),
    );
  }

  @override
  Future<LlmResult> classifyWord(String word, {Map<String, dynamic>? dictionaryHit}) => _completeJson(
        model: _env.openAiModel,
        systemPrompt: kWordClassificationSystemPrompt,
        userPrompt: buildWordClassificationUserPrompt(word: word, dictionaryHit: dictionaryHit),
      );

  Future<LlmResult> _completeJson({
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await _chatCompletion(
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: true,
    );
    final content = _extractContent(response);
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      // One controlled retry with a stricter reminder, per spec §19.
      final retryResponse = await _chatCompletion(
        model: model,
        systemPrompt: '$systemPrompt\n\nIMPORTANT: your previous response was not valid JSON. '
            'Respond with ONLY the JSON object, no markdown fences, no commentary.',
        userPrompt: userPrompt,
        jsonMode: true,
      );
      final retryContent = _extractContent(retryResponse);
      try {
        parsed = jsonDecode(retryContent) as Map<String, dynamic>;
      } on FormatException {
        throw AppException.translationFailed('The translation engine returned an invalid response.');
      }
    }
    return LlmResult(
      json: parsed,
      modelUsed: response['model'] as String?,
      rawText: content,
      usage: _extractUsage(response),
    );
  }

  Future<String> _completeText({
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await _chatCompletion(
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: false,
    );
    return _extractContent(response);
  }

  Future<Map<String, dynamic>> _chatCompletion({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required bool jsonMode,
  }) async {
    final apiKey = _apiKeyOverride ?? _env.openAiApiKey;
    if (apiKey == null) {
      throw AppException.upstreamUnavailable(
        'The translation engine is not configured (missing OPENAI_API_KEY).',
      );
    }

    http.Response httpResponse;
    try {
      httpResponse = await _httpClient
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'max_tokens': _env.llmMaxOutputTokens,
              'temperature': 0.2,
              if (jsonMode) 'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(_timeoutOverride ?? Duration(seconds: _env.llmRequestTimeoutSeconds));
    } catch (_) {
      throw AppException.upstreamUnavailable('The translation engine did not respond in time.');
    }

    if (httpResponse.statusCode == 429 ||
        httpResponse.statusCode == 401 ||
        httpResponse.statusCode == 403) {
      // 429 = rate limited; OpenRouter also returns 401/403 for a key whose
      // free-tier daily quota is exhausted. Either way, this specific key
      // is temporarily spent, not that the request itself is invalid.
      throw LlmRateLimitedException(httpResponse.statusCode, httpResponse.body);
    }

    if (httpResponse.statusCode >= 400) {
      throw AppException.upstreamUnavailable(
        'The translation engine returned an error (${httpResponse.statusCode}).',
      );
    }

    return jsonDecode(httpResponse.body) as Map<String, dynamic>;
  }

  String _extractContent(Map<String, dynamic> response) {
    final choices = response['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AppException.translationFailed('The translation engine returned no output.');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw AppException.translationFailed('The translation engine returned no output.');
    }
    return content;
  }

  Map<String, int>? _extractUsage(Map<String, dynamic> response) {
    final usage = response['usage'] as Map<String, dynamic>?;
    if (usage == null) return null;
    return {
      'prompt_tokens': (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
      'completion_tokens': (usage['completion_tokens'] as num?)?.toInt() ?? 0,
      'total_tokens': (usage['total_tokens'] as num?)?.toInt() ?? 0,
    };
  }
}
