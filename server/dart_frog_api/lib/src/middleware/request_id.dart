import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';

import '../core/logging/request_logger.dart';

const _uuid = Uuid();

/// Wrapper so the request id can be provided/read via Dart Frog's
/// type-based DI (`context.read<RequestId>()`) without colliding with any
/// other provided `String`.
class RequestId {
  const RequestId(this.value);
  final String value;
}

/// Injects a `request_id` (from the incoming header if present, otherwise a
/// fresh UUID) into the context so every downstream handler/log line can
/// reference the same id, and logs request start/latency/status.
Middleware requestIdMiddleware() {
  return (handler) {
    return (context) async {
      final incoming = context.request.headers['x-request-id'];
      final requestId = (incoming != null && incoming.isNotEmpty) ? incoming : _uuid.v4();
      final stopwatch = Stopwatch()..start();

      final updatedContext = context.provide<RequestId>(() => RequestId(requestId));

      RequestLogger.log(
        'request.start',
        requestId: requestId,
        fields: {
          'method': context.request.method.value,
          'path': context.request.uri.path,
        },
      );

      final response = await handler(updatedContext);
      stopwatch.stop();

      RequestLogger.log(
        'request.end',
        requestId: requestId,
        fields: {
          'status_code': response.statusCode,
          'latency_ms': stopwatch.elapsedMilliseconds,
        },
      );

      return response.copyWith(headers: {...response.headers, 'X-Request-Id': requestId});
    };
  };
}
