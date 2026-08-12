import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/api/v1/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /api/v1/health', () {
    late _MockRequestContext context;
    late _MockRequest request;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.request).thenReturn(request);
    });

    test('responds with 200 and status ok for GET', () async {
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = route.onRequest(context);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
      expect(body['timestamp'], isNotNull);
    });

    test('responds with 405 for non-GET methods', () {
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = route.onRequest(context);

      expect(response.statusCode, equals(405));
    });
  });
}
