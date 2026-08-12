import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/auth.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/middleware/request_id.dart';
import 'package:shared_models/shared_models.dart';

/// POST /api/v1/chat — conversational wrapper around the same translation
/// orchestrator used by /translate, but auto-creates and persists a
/// conversation when the caller is authenticated (spec §30, §60: "the
/// system remembers conversation context"). Anonymous callers still get a
/// translation back; it just isn't saved. Multi-turn follow-up questions
/// beyond "translate this" are a future extension (see docs/BUILD_PHASES.md)
/// — today every turn is treated as a new Sanskrit input to translate.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final requestId = context.read<RequestId>().value;
  final body = await readJsonBody(context);
  final translationRequest = TranslationRequest.fromJson(body);
  final auth = context.read<AuthContext>();
  final services = await context.read<Future<AppServices>>();

  final response = await services.orchestrator.translate(translationRequest, requestId: requestId);

  String? conversationId = translationRequest.conversationId;
  if (auth.isAuthenticated) {
    if (conversationId == null) {
      final title = translationRequest.text.length > 40
          ? '${translationRequest.text.substring(0, 40)}…'
          : translationRequest.text;
      final conversation = await services.conversationRepository.create(userId: auth.userId!, title: title);
      conversationId = conversation.id;
    } else {
      final existing = await services.conversationRepository.findById(conversationId);
      if (existing == null) throw AppException.notFound('Conversation not found.');
      if (existing.userId != auth.userId) throw AppException.forbidden();
    }

    await services.conversationRepository.addMessage(
      conversationId: conversationId,
      role: MessageRole.user,
      content: translationRequest.text,
    );
    await services.conversationRepository.addMessage(
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: response.translations['en'] ?? '',
      translationMetadata: response.toJson(),
      modelVersion: response.metadata?.modelVersion,
    );
  }

  return Response.json(body: {
    'conversation_id': conversationId,
    'translation': response.toJson(),
  });
}
