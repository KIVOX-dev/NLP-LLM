import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/middleware/request_id.dart';
import 'package:shared_models/shared_models.dart';

/// POST /api/v1/analyze — linguistic analysis only (word analysis, grammar,
/// sandhi, compounds, pronunciation), no translation prose. Reuses the same
/// orchestrator pipeline as /translate for consistency, then strips the
/// translation-specific fields from the response.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final requestId = context.read<RequestId>().value;
  final body = await readJsonBody(context);
  final translationRequest = TranslationRequest(
    text: body['text'] as String? ?? '',
    includeWordAnalysis: true,
    includeGrammar: true,
    includePronunciation: body['include_pronunciation'] as bool? ?? true,
    includeSandhi: body['include_sandhi'] as bool? ?? true,
    includeCompounds: body['include_compounds'] as bool? ?? true,
    targets: const [TargetLanguage.english],
  );

  final services = await context.read<Future<AppServices>>();
  final response = await services.orchestrator.translate(translationRequest, requestId: requestId);

  return Response.json(body: {
    'request_id': response.requestId,
    'source': response.source.toJson(),
    'words': response.words.map((w) => w.toJson()).toList(),
    'grammar': response.grammar?.toJson(),
    'sandhi': response.sandhi.map((s) => s.toJson()).toList(),
    'compounds': response.compounds.map((c) => c.toJson()).toList(),
    'pronunciation': response.pronunciation?.toJson(),
    'confidence': response.confidence?.toJson(),
    'uncertainties': response.uncertainties,
  });
}
