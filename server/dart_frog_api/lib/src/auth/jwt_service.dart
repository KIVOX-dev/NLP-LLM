import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../config/env_config.dart';
import '../core/errors/app_exception.dart';

/// Thin wrapper around dart_jsonwebtoken so the rest of the app never
/// touches the JWT library directly (spec §31). Access tokens only for now;
/// refresh-token rotation is a future extension (see docs/BUILD_PHASES.md).
class JwtService {
  JwtService(this._env);

  final EnvConfig _env;

  String issueAccessToken({required String userId, required String email}) {
    final jwt = JWT(
      {'sub': userId, 'email': email},
      issuer: 'sanskrit-ai-translator',
    );
    return jwt.sign(
      SecretKey(_env.jwtSecret),
      expiresIn: Duration(minutes: _env.getIntOrDefault('JWT_ACCESS_TOKEN_TTL_MINUTES', 15)),
    );
  }

  /// Returns the decoded payload (contains `sub`, `email`) or throws
  /// [AppException.unauthorized] when the token is missing, malformed,
  /// expired, or has an invalid signature.
  Map<String, dynamic> verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_env.jwtSecret));
      return Map<String, dynamic>.from(jwt.payload as Map);
    } catch (_) {
      throw AppException.unauthorized('Invalid or expired session. Please sign in again.');
    }
  }
}
