import 'package:dart_frog/dart_frog.dart';

const String _apiVersion = 'v1';
const String _appVersion = '0.1.0';

/// GET /api/v1/version
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }
  return Response.json(body: {
    'api_version': _apiVersion,
    'app_version': _appVersion,
  });
}
