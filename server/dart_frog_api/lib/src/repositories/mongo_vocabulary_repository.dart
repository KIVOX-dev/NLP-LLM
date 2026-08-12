import 'package:mongo_dart/mongo_dart.dart';

import '../db/mongo_client.dart';
import 'vocabulary_repository.dart';

class MongoVocabularyRepository implements VocabularyRepository {
  MongoVocabularyRepository(this._mongo);

  final MongoClientService _mongo;

  DbCollection get _collection => _mongo.collection(Collections.sanskritWords);

  @override
  Future<VocabularyEntry?> findByLemma(String lemma) async {
    final doc = await _collection.findOne(
      where.eq('lemma', lemma).or(where.eq('iast', lemma)),
    );
    return doc == null ? null : VocabularyEntry.fromMap(doc);
  }

  @override
  Future<VocabularyEntry?> findBySurfaceForm(String surface) async {
    final doc = await _collection.findOne(where.eq('surface_forms', surface));
    return doc == null ? null : VocabularyEntry.fromMap(doc);
  }

  @override
  Future<List<VocabularyEntry>> search(String query, {int limit = 20}) async {
    final selector = where
        .match('lemma', query, caseInsensitive: true)
        .or(where.match('iast', query, caseInsensitive: true))
        .or(where.match('surface_forms', query, caseInsensitive: true))
        .or(where.match('english_meanings', query, caseInsensitive: true))
        .or(where.match('tamil_meanings', query, caseInsensitive: true))
        .limit(limit);
    final docs = await _collection.find(selector).toList();
    return docs.map(VocabularyEntry.fromMap).toList();
  }
}

/// Indexes required for §16. Call once during deployment/setup, not per request.
Future<void> ensureVocabularyIndexes(MongoClientService mongo) async {
  final collection = mongo.collection(Collections.sanskritWords);
  await collection.createIndex(keys: {'lemma': 1});
  await collection.createIndex(keys: {'iast': 1});
  await collection.createIndex(keys: {'surface_forms': 1});
  await collection.createIndex(keys: {'english_meanings': 1});
  await collection.createIndex(keys: {'tamil_meanings': 1});
}
