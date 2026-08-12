import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/auth.dart';

/// GET /api/v1/conversations/:id — conversation + its messages.
/// DELETE /api/v1/conversations/:id
Future<Response> onRequest(RequestContext context, String id) async {
  final auth = requireAuth(context);
  final services = await context.read<Future<AppServices>>();

  final conversation = await services.conversationRepository.findById(id);
  if (conversation == null) {
    throw AppException.notFound('Conversation not found.');
  }
  if (conversation.userId != auth.userId) {
    throw AppException.forbidden();
  }

  switch (context.request.method) {
    case HttpMethod.get:
      final messages = await services.conversationRepository.listMessages(id);
      return Response.json(body: {
        'conversation': conversation.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(),
      });

    case HttpMethod.delete:
      await services.conversationRepository.delete(id);
      return Response(statusCode: 204);

    default:
      return Response(statusCode: 405);
  }
}
