import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../core/errors/app_exception.dart';

/// Calls the OpenAI-compatible `/embeddings` endpoint (OpenRouter proxies
/// this the same as chat completions — see EMBEDDING_MODEL in .env).
/// Separate from [LLMProvider] because embeddings are a distinct API
/// surface (no chat messages, no JSON-mode response), not because the
/// provider is different.
class EmbeddingService {
  EmbeddingService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final EnvConfig _env = EnvConfig.instance;

  Future<List<double>> embed(String text) async {
    final apiKey = _env.openAiApiKey;
    final model = _env.embeddingModel;
    if (apiKey == null || model.isEmpty) {
      throw AppException.upstreamUnavailable('Embeddings are not configured (OPENAI_API_KEY / EMBEDDING_MODEL).');
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse('${_env.openAiBaseUrl}/embeddings'),
            headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
            body: jsonEncode({'model': model, 'input': text}),
          )
          .timeout(Duration(seconds: _env.llmRequestTimeoutSeconds));
    } catch (_) {
      throw AppException.upstreamUnavailable('The embedding service did not respond in time.');
    }

    if (response.statusCode >= 400) {
      throw AppException.upstreamUnavailable('The embedding service returned an error (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;
    final embedding = (data.first as Map<String, dynamic>)['embedding'] as List<dynamic>;
    return embedding.cast<num>().map((n) => n.toDouble()).toList();
  }
}
