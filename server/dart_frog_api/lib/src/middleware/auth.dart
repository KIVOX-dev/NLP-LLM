import 'package:dart_frog/dart_frog.dart';

import '../auth/jwt_service.dart';
import '../core/errors/app_exception.dart';

/// Authenticated principal extracted from a verified JWT. `null` fields mean
/// "not authenticated" (see [optionalAuthMiddleware]) rather than "guest
/// user" — callers that require a real user must call [requireAuth].
class AuthContext {
  const AuthContext({this.userId, this.email});

  final String? userId;
  final String? email;

  bool get isAuthenticated => userId != null;
}

/// Attaches an [AuthContext] to every request without rejecting anonymous
/// ones — endpoints that must be authenticated call [requireAuth] on it
/// themselves. This lets read-only/demo endpoints stay reachable while the
/// full registration/login flow (spec §31) is built out.
Middleware optionalAuthMiddleware(JwtService jwtService) {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['authorization'];
      AuthContext authContext = const AuthContext();

      if (authHeader != null && authHeader.toLowerCase().startsWith('bearer ')) {
        final token = authHeader.substring(7).trim();
        if (token.isNotEmpty) {
          try {
            final payload = jwtService.verify(token);
            authContext = AuthContext(
              userId: payload['sub'] as String?,
              email: payload['email'] as String?,
            );
          } on AppException {
            // Invalid token on an optional-auth route: proceed as anonymous
            // rather than failing the whole request.
          }
        }
      }

      return handler(context.provide<AuthContext>(() => authContext));
    };
  };
}

AuthContext requireAuth(RequestContext context) {
  final auth = context.read<AuthContext>();
  if (!auth.isAuthenticated) {
    throw AppException.unauthorized();
  }
  return auth;
}
