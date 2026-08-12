import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/health — liveness check. Deliberately has no dependency on
/// Mongo/LLM configuration so it can be used as a basic "is the process up"
/// probe even before those are configured.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  return Response.json(body: {
    'status': 'ok',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
}
