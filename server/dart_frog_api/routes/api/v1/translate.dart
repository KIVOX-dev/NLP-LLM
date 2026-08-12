import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/middleware/request_id.dart';
import 'package:shared_models/shared_models.dart';

/// POST /api/v1/translate — spec §10. The only endpoint the Flutter app's
/// core chat flow needs; everything else (dictionary, sandhi, analyze,
/// conversations) is a thinner slice of the same orchestrator/repositories.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final requestId = context.read<RequestId>().value;
  final body = await readJsonBody(context);
  final translationRequest = TranslationRequest.fromJson(body);

  final services = await context.read<Future<AppServices>>();

  final response = await services.orchestrator.translate(translationRequest, requestId: requestId);

  if (translationRequest.conversationId != null) {
    await _persistToConversation(services, translationRequest, response);
  }

  return Response.json(body: response.toJson());
}

Future<void> _persistToConversation(
  AppServices services,
  TranslationRequest request,
  TranslationResponse response,
) async {
  final conversationId = request.conversationId!;
  final conversation = await services.conversationRepository.findById(conversationId);
  if (conversation == null) {
    throw AppException.notFound('Conversation not found.');
  }

  await services.conversationRepository.addMessage(
    conversationId: conversationId,
    role: MessageRole.user,
    content: request.text,
  );
  await services.conversationRepository.addMessage(
    conversationId: conversationId,
    role: MessageRole.assistant,
    content: response.translations['en'] ?? response.translations.values.firstOrNull ?? '',
    translationMetadata: response.toJson(),
    modelVersion: response.metadata?.modelVersion,
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
