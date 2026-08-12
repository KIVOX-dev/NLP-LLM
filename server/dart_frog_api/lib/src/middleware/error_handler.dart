import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../core/logging/request_logger.dart';
import 'request_id.dart';

const _uuid = Uuid();

/// Single place where any exception thrown by a route/service is turned
/// into the standard `{"error": {...}}` envelope (spec §33). Never forwards
/// a stack trace or raw exception message to the client.
Middleware errorHandlerMiddleware() {
  return (handler) {
    return (context) async {
      String requestId;
      try {
        requestId = context.read<RequestId>().value;
      } catch (_) {
        requestId = _uuid.v4();
      }

      try {
        return await handler(context);
      } on AppException catch (e) {
        RequestLogger.error(
          'request.app_exception',
          requestId: requestId,
          errorCode: e.code,
          errorMessage: e.message,
        );
        return Response.json(
          statusCode: e.statusCode,
          body: ApiErrorResponse(
            code: e.code,
            message: e.message,
            requestId: requestId,
            details: e.details,
          ).toJson(),
        );
      } on FormatException catch (e) {
        RequestLogger.error(
          'request.format_exception',
          requestId: requestId,
          errorCode: ApiErrorCode.validationFailed,
          errorMessage: e.message,
        );
        return Response.json(
          statusCode: 400,
          body: ApiErrorResponse(
            code: ApiErrorCode.validationFailed,
            message: 'The request body is not valid JSON.',
            requestId: requestId,
          ).toJson(),
        );
      } catch (e, stackTrace) {
        // Internal error: log details server-side, never leak them to the client.
        RequestLogger.error(
          'request.unhandled_exception',
          requestId: requestId,
          errorCode: ApiErrorCode.internalError,
          errorMessage: e.toString(),
          fields: {'stack_trace': stackTrace.toString()},
        );
        return Response.json(
          statusCode: 500,
          body: ApiErrorResponse(
            code: ApiErrorCode.internalError,
            message: 'Something went wrong. Please try again.',
            requestId: requestId,
          ).toJson(),
        );
      }
    };
  };
}

/// Convenience for handlers that need to jsonDecode a request body and want
/// a clean VALIDATION_FAILED error instead of a raw FormatException string.
Future<Map<String, dynamic>> readJsonBody(RequestContext context) async {
  final body = await context.request.body();
  if (body.trim().isEmpty) return {};
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw AppException.validation('Request body must be a JSON object.');
  }
  return decoded;
}
