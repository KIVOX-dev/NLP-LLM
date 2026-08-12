import 'package:shared_models/shared_models.dart';

/// Thrown by services/repositories; caught once by the global error-handling
/// middleware and turned into an [ApiErrorResponse]. Route handlers should
/// throw this instead of building error responses inline.
class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details,
  });

  factory AppException.validation(String message, {Map<String, dynamic>? details}) => AppException(
        code: ApiErrorCode.validationFailed,
        message: message,
        statusCode: 400,
        details: details,
      );

  factory AppException.notFound(String message) => AppException(
        code: ApiErrorCode.notFound,
        message: message,
        statusCode: 404,
      );

  factory AppException.unauthorized([String message = 'Authentication required.']) => AppException(
        code: ApiErrorCode.unauthorized,
        message: message,
        statusCode: 401,
      );

  factory AppException.forbidden([String message = 'Not allowed.']) => AppException(
        code: ApiErrorCode.forbidden,
        message: message,
        statusCode: 403,
      );

  factory AppException.rateLimited([String message = 'Too many requests.']) => AppException(
        code: ApiErrorCode.rateLimited,
        message: message,
        statusCode: 429,
      );

  factory AppException.translationFailed(String message) => AppException(
        code: ApiErrorCode.translationFailed,
        message: message,
        statusCode: 502,
      );

  factory AppException.upstreamUnavailable(String message) => AppException(
        code: ApiErrorCode.upstreamUnavailable,
        message: message,
        statusCode: 503,
      );

  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;
}
