/// Standard error envelope returned by every endpoint on failure.
/// Never carries a stack trace or internal exception message.
class ApiErrorResponse {
  const ApiErrorResponse({
    required this.code,
    required this.message,
    required this.requestId,
    this.details,
  });

  final String code;
  final String message;
  final String requestId;
  final Map<String, dynamic>? details;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>? ?? json;
    return ApiErrorResponse(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? 'An unknown error occurred.',
      requestId: error['request_id'] as String? ?? '',
      details: error['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'error': {
          'code': code,
          'message': message,
          'request_id': requestId,
          if (details != null) 'details': details,
        },
      };
}

/// Well-known error codes used across the API. Keeping these centralized
/// avoids typo drift between routes and lets the client switch on them.
abstract final class ApiErrorCode {
  static const validationFailed = 'VALIDATION_FAILED';
  static const translationFailed = 'TRANSLATION_FAILED';
  static const notFound = 'NOT_FOUND';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const rateLimited = 'RATE_LIMITED';
  static const upstreamUnavailable = 'UPSTREAM_UNAVAILABLE';
  static const internalError = 'INTERNAL_ERROR';
}
