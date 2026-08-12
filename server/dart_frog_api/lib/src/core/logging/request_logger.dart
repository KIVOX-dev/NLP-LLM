import 'dart:convert';

/// Minimal structured (line-delimited JSON) logger. Never log secrets or
/// full conversation content — pass identifiers/sizes, not raw payloads.
abstract final class RequestLogger {
  static void log(
    String event, {
    required String requestId,
    Map<String, Object?> fields = const {},
  }) {
    final entry = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'event': event,
      'request_id': requestId,
      ...fields,
    };
    // ignore: avoid_print
    print(jsonEncode(entry));
  }

  static void error(
    String event, {
    required String requestId,
    required String errorCode,
    String? errorMessage,
    Map<String, Object?> fields = const {},
  }) {
    log(
      event,
      requestId: requestId,
      fields: {
        'level': 'error',
        'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
        ...fields,
      },
    );
  }
}
