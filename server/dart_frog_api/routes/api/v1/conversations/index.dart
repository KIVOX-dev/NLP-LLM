import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/auth.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';

/// GET /api/v1/conversations — list the authenticated user's conversations.
/// POST /api/v1/conversations — create a new (empty) conversation.
Future<Response> onRequest(RequestContext context) async {
  final auth = requireAuth(context);
  final services = await context.read<Future<AppServices>>();

  switch (context.request.method) {
    case HttpMethod.get:
      final conversations = await services.conversationRepository.listForUser(auth.userId!);
      return Response.json(body: {'conversations': conversations.map((c) => c.toJson()).toList()});

    case HttpMethod.post:
      final body = await readJsonBody(context);
      final title = (body['title'] as String?)?.trim();
      if (title == null || title.isEmpty) {
        throw AppException.validation('title is required.');
      }
      final conversation = await services.conversationRepository.create(userId: auth.userId!, title: title);
      return Response.json(statusCode: 201, body: conversation.toJson());

    default:
      return Response(statusCode: 405);
  }
}
