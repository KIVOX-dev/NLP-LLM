import '../config/env_config.dart';
import '../db/mongo_client.dart';
import 'embedding_service.dart';

/// Abstraction over similarity search so the retrieval backend (MongoDB
/// Atlas Vector Search today; something else tomorrow) never leaks into the
/// orchestrator (spec §17).
abstract class VectorSearchService {
  Future<List<Map<String, dynamic>>> searchVocabulary(String query, {int limit = 5});
  Future<List<Map<String, dynamic>>> searchSentences(String query, {int limit = 5});
  Future<List<Map<String, dynamic>>> searchGrammarExamples(String query, {int limit = 5});
  Future<List<Map<String, dynamic>>> searchSimilarTranslations(String query, {int limit = 5});
}

/// Used until an embedding model + Atlas Vector Search index are configured
/// (`EMBEDDING_MODEL` / `VECTOR_INDEX_NAME` in .env). Returns no results
/// rather than fabricating retrieval evidence — the orchestrator and prompt
/// both handle an empty retrieval set explicitly.
class NoOpVectorSearchService implements VectorSearchService {
  const NoOpVectorSearchService();

  @override
  Future<List<Map<String, dynamic>>> searchGrammarExamples(String query, {int limit = 5}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> searchSentences(String query, {int limit = 5}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> searchSimilarTranslations(String query, {int limit = 5}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> searchVocabulary(String query, {int limit = 5}) async => const [];
}

/// Real Atlas Vector Search implementation, backed by the `embeddings`
/// collection (see scripts/create_embeddings.dart) and the `$vectorSearch`
/// aggregation stage. Only `searchSimilarTranslations` is wired to real
/// retrieval — that's the only one the orchestrator currently calls (see
/// TranslationOrchestrator.translate, step 10). The other three methods
/// return no results rather than a fabricated/untested approximation, same
/// as [NoOpVectorSearchService], until there's an actual caller and data
/// shape to build them against.
class MongoVectorSearchService implements VectorSearchService {
  MongoVectorSearchService(this._mongo, {EmbeddingService? embeddingService})
      : _embeddingService = embeddingService ?? EmbeddingService();

  final MongoClientService _mongo;
  final EmbeddingService _embeddingService;
  final EnvConfig _env = EnvConfig.instance;

  @override
  Future<List<Map<String, dynamic>>> searchSimilarTranslations(String query, {int limit = 5}) async {
    final indexName = _env.vectorIndexName;
    if (indexName.isEmpty) return const [];

    final queryVector = await _embeddingService.embed(query);

    final results = await _mongo
        .collection(Collections.embeddings)
        .aggregateToStream([
          {
            r'$vectorSearch': {
              'index': indexName,
              'path': 'vector',
              'queryVector': queryVector,
              'numCandidates': limit * 20,
              'limit': limit,
            },
          },
          {
            r'$lookup': {
              'from': Collections.sanskritSentences,
              'localField': '_id',
              'foreignField': '_id',
              'as': 'sentence',
            },
          },
          {
            r'$unwind': r'$sentence',
          },
          {
            r'$project': {
              '_id': 0,
              'sanskrit': r'$sentence.sanskrit',
              'english': r'$sentence.english',
              'tamil': r'$sentence.tamil',
              'score': {r'$meta': 'vectorSearchScore'},
            },
          },
        ])
        .toList();

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> searchGrammarExamples(String query, {int limit = 5}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> searchSentences(String query, {int limit = 5}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> searchVocabulary(String query, {int limit = 5}) async => const [];
}
