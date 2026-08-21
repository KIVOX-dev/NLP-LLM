import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:shared_models/shared_models.dart';

/// POST /api/v1/word-classify — classifies a single Sanskrit word as
/// name/place/animal/thing (the classic word-game categories) and returns
/// one grounded example sentence with its English translation.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final request = WordClassificationRequest.fromJson(body);

  final errors = request.validate();
  if (errors.isNotEmpty) {
    throw AppException.validation(errors.join('; '));
  }

  final services = await context.read<Future<AppServices>>();
  final response = await services.wordClassificationService.classify(request.word);

  return Response.json(body: response.toJson());
}
