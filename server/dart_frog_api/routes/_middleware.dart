import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/auth/jwt_service.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/config/env_config.dart';
import 'package:dart_frog_api/src/middleware/auth.dart';
import 'package:dart_frog_api/src/middleware/cors.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/middleware/rate_limiter.dart';
import 'package:dart_frog_api/src/middleware/request_id.dart';

final _rateLimiter = RateLimiter();

/// Global middleware pipeline. Order matters — see the comment in each
/// middleware file for why. Net effect, outermost to innermost:
/// requestId -> cors -> errorHandler -> auth -> rateLimit -> [services] -> route.
/// This guarantees every response (success or error) gets a request id and
/// CORS headers, and that no exception from auth/rate-limiting/the route
/// itself ever reaches the client unhandled.
Handler middleware(Handler handler) {
  return handler
      .use(provider<Future<AppServices>>((_) => AppServices.instance()))
      .use(rateLimitMiddleware(_rateLimiter))
      .use(optionalAuthMiddleware(JwtService(EnvConfig.instance)))
      .use(errorHandlerMiddleware())
      .use(corsMiddleware())
      .use(requestIdMiddleware());
}
