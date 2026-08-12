import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:shared_models/shared_models.dart';

/// POST /api/v1/feedback — thumbs up/down or a full correction (spec §29).
/// Anonymous feedback is allowed (no login wall on giving feedback), but is
/// stored without a user id.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final feedback = TranslationFeedback.fromJson(body);
  final errors = feedback.validate();
  if (errors.isNotEmpty) {
    throw AppException.validation(errors.join('; '));
  }

  final services = await context.read<Future<AppServices>>();
  final id = await services.feedbackRepository.record(feedback);

  return Response.json(statusCode: 201, body: {'id': id});
}
