import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/middleware/error_handler.dart';
import 'package:dart_frog_api/src/repositories/vocabulary_repository.dart';

/// POST /api/v1/dictionary/search
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await readJsonBody(context);
  final query = body['query'] as String?;
  if (query == null || query.trim().isEmpty) {
    throw AppException.validation('query is required.');
  }
  final limit = (body['limit'] as num?)?.toInt() ?? 20;

  final services = await context.read<Future<AppServices>>();
  final results = await services.vocabularyRepository.search(query, limit: limit);

  return Response.json(body: {'results': results.map(_toJson).toList()});
}

Map<String, dynamic> _toJson(VocabularyEntry entry) => {
      'id': entry.id,
      'lemma': entry.lemma,
      'iast': entry.iast,
      'pos': entry.pos,
      'gender': entry.gender,
      'english_meanings': entry.englishMeanings,
      'tamil_meanings': entry.tamilMeanings,
      'domains': entry.domains,
      'source_name': entry.sourceName,
      'source_type': entry.sourceType,
      'verified': entry.verified,
    };
