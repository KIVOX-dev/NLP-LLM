import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../db/mongo_client.dart';

const _uuid = Uuid();

abstract class FeedbackRepository {
  Future<String> record(TranslationFeedback feedback);
}

/// Persists feedback exactly as submitted (spec §29) for later evaluation /
/// supervised-improvement use. This data is never treated as authoritative
/// ground truth on its own — it's a candidate for human review.
class MongoFeedbackRepository implements FeedbackRepository {
  MongoFeedbackRepository(this._mongo);

  final MongoClientService _mongo;

  DbCollection get _collection => _mongo.collection(Collections.translationFeedback);

  @override
  Future<String> record(TranslationFeedback feedback) async {
    final id = _uuid.v4();
    await _collection.insertOne({
      '_id': id,
      ...feedback.toJson(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }
}
