import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_api/src/bootstrap.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/repositories/vocabulary_repository.dart';

/// GET /api/v1/dictionary/:word
Future<Response> onRequest(RequestContext context, String word) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final decodedWord = Uri.decodeComponent(word);
  final services = await context.read<Future<AppServices>>();
  final entry = await services.vocabularyRepository.findByLemma(decodedWord) ??
      await services.vocabularyRepository.findBySurfaceForm(decodedWord);

  if (entry == null) {
    throw AppException.notFound('No dictionary entry found for "$decodedWord".');
  }

  return Response.json(body: _toJson(entry));
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
