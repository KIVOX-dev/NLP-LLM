import 'package:dart_frog_api/src/db/mongo_client.dart';

/// Wraps a single Mongo write with reconnect-on-failure. Atlas free-tier
/// (M0) clusters drop the connection after a batch of rapid operations, and
/// mongo_dart doesn't auto-reconnect — every write after that fails with
/// "No master connection" even though the cluster is healthy. Batch import
/// scripts call this instead of writing directly so a mid-run drop doesn't
/// kill the whole job.
class MongoRetryWriter {
  MongoRetryWriter(this._mongo);

  MongoClientService _mongo;
  MongoClientService get mongo => _mongo;

  Future<T> write<T>(Future<T> Function(MongoClientService mongo) op, {int maxAttempts = 4}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await op(_mongo);
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        _mongo = await MongoClientService.reconnect();
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }
    throw StateError('unreachable');
  }
}
