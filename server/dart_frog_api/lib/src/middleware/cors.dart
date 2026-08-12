import 'package:dart_frog/dart_frog.dart';

import '../config/env_config.dart';

/// Applies CORS headers based on `CORS_ORIGINS`. When no origins are
/// configured, defaults to allowing none in production and `*` only in
/// development, so a forgotten env var fails safe rather than open.
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      final env = EnvConfig.instance;
      final requestOrigin = context.request.headers['origin'];
      final allowedOrigins = env.corsOrigins;

      String? allowOrigin;
      if (allowedOrigins.contains('*')) {
        allowOrigin = '*';
      } else if (requestOrigin != null && allowedOrigins.contains(requestOrigin)) {
        allowOrigin = requestOrigin;
      } else if (allowedOrigins.isEmpty && !env.isProduction) {
        allowOrigin = requestOrigin ?? '*';
      }

      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 204,
          headers: _corsHeaders(allowOrigin),
        );
      }

      final response = await handler(context);
      return response.copyWith(headers: {...response.headers, ..._corsHeaders(allowOrigin)});
    };
  };
}

Map<String, String> _corsHeaders(String? allowOrigin) => {
      if (allowOrigin != null) 'Access-Control-Allow-Origin': allowOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Vary': 'Origin',
    };
