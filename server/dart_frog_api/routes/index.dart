import 'package:dart_frog/dart_frog.dart';

/// GET / — points visitors at the API; this backend has no UI of its own.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  return Response.json(body: {
    'service': 'dart_frog_api',
    'message': 'This is the SanskritAI Translator API. There is no UI here — the app runs at http://localhost:5000.',
    'health': '/api/v1/health',
    'version': '/api/v1/version',
  });
}
