import 'package:mongo_dart/mongo_dart.dart';

import '../config/env_config.dart';

/// Thin wrapper around a single [Db] connection, shared via Dart Frog's
/// dependency-injection `provider<T>()` so every route/repository reuses the
/// same pooled connection instead of opening a new one per request.
class MongoClientService {
  MongoClientService._(this._db);

  final Db _db;

  static MongoClientService? _instance;

  static Future<MongoClientService> connect() async {
    if (_instance != null) return _instance!;
    final uri = _resolveDatabaseInUri(EnvConfig.instance.mongoUri, EnvConfig.instance.mongoDatabase);
    final db = await Db.create(uri);
    await db.open();
    _instance = MongoClientService._(db);
    return _instance!;
  }

  /// Many Atlas connection strings (e.g. copied straight from the Atlas UI)
  /// omit the database name from the path — `mongodb+srv://user:pass@host/?appName=...`.
  /// mongo_dart connects to whatever database the URI path names, so without
  /// this the driver would fall back to an unintended default database.
  /// If the URI already names a database, it's left untouched.
  static String _resolveDatabaseInUri(String uri, String database) {
    final parsed = Uri.parse(uri);
    final hasDatabase = parsed.pathSegments.isNotEmpty && parsed.pathSegments.first.isNotEmpty;
    if (hasDatabase) return uri;
    return parsed.replace(path: '/$database').toString();
  }

  Db get db => _db;

  DbCollection collection(String name) => _db.collection(name);

  Future<void> close() => _db.close();
}

/// Collection name constants, per spec §4 schema.
abstract final class Collections {
  static const users = 'users';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const sanskritWords = 'sanskrit_words';
  static const sanskritRoots = 'sanskrit_roots';
  static const sanskritForms = 'sanskrit_forms';
  static const sanskritSentences = 'sanskrit_sentences';
  static const translations = 'translations';
  static const translationFeedback = 'translation_feedback';
  static const pronunciation = 'pronunciation';
  static const accentData = 'accent_data';
  static const embeddings = 'embeddings';
  static const trainingExamples = 'training_examples';
  static const modelVersions = 'model_versions';
  static const apiUsage = 'api_usage';
}
