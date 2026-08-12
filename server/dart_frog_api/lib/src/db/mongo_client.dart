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
    return _openNewConnection();
  }

  /// Atlas free-tier (M0) clusters reset idle/long-lived connections after a
  /// batch of operations, and mongo_dart doesn't auto-reconnect once that
  /// happens — every further call fails with "No master connection" even
  /// though the cluster itself is fine. Long-running batch scripts (the
  /// dataset importers) call this to discard the dead connection and open a
  /// fresh one rather than getting permanently stuck. The live API server
  /// doesn't need this: each request is short, so a mid-request drop is rare
  /// and simply surfaces as one failed request rather than a stuck process.
  static Future<MongoClientService> reconnect() async {
    try {
      await _instance?._db.close();
    } catch (_) {
      // The connection is already dead; nothing to clean up.
    }
    _instance = null;
    return _openNewConnection();
  }

  static Future<MongoClientService> _openNewConnection() async {
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

  // Monolingual reference corpora (not in the original spec §4 list — added
  // to hold bounded samples pulled from Kaggle). These are NOT parallel/
  // aligned with sanskrit_sentences; they exist for future vocabulary/
  // embedding work in each language individually, not as translation pairs.
  static const englishVocabulary = 'english_vocabulary';
  static const tamilCorpusSentences = 'tamil_corpus_sentences';
}
