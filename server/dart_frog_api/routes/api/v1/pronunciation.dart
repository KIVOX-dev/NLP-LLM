import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/nlp/pronunciation_service.dart';

/// POST /api/v1/pronunciation — deterministic syllabification/IAST guide,
/// no LLM call. See PronunciationService for the algorithm and its scope
/// limitations (spec §21: not a claim of exact phonetic realization).
final _service = PronunciationService();

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final text = body['text'] as String?;
  if (text == null || text.trim().isEmpty) {
    throw AppException.validation('text is required.');
  }

  return Response.json(body: _service.analyze(text).toJson());
}
