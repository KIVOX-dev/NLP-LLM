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
