import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/nlp/sandhi_analyzer.dart';

/// POST /api/v1/sandhi — rule-based sandhi splitting only, no LLM call
/// (cheap, deterministic; see spec §51 cost-control intent). For LLM-assisted
/// sandhi resolution on ambiguous cases, use /api/v1/analyze instead.
final _analyzer = RuleBasedSandhiAnalyzer();

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final text = body['text'] as String?;
  if (text == null || text.trim().isEmpty) {
    throw AppException.validation('text is required.');
  }

  final results = _analyzer.analyzeSentence(text);
  return Response.json(body: {
    'source': text,
    'sandhi': results.map((r) => r.toJson()).toList(),
  });
}
