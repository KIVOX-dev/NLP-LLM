// Creates the Atlas Vector Search index on the `embeddings` collection via
// the createSearchIndexes database command (works over the normal MongoDB
// connection on Atlas, including the free M0 tier — no separate Atlas Admin
// API key needed). One-time setup step; safe to re-run (Atlas rejects a
// duplicate index name with a clear error rather than corrupting anything).
//
// Usage: dart run create_vector_index.dart

import 'dart:io';

import 'package:dart_frog_api/src/config/env_config.dart';
import 'package:dart_frog_api/src/db/mongo_client.dart';

Future<void> main() async {
  final indexName = EnvConfig.instance.getOrDefault('VECTOR_INDEX_NAME', '');
  if (indexName.isEmpty) {
    stderr.writeln('VECTOR_INDEX_NAME is not set in .env.');
    exitCode = 1;
    return;
  }

  final mongo = await MongoClientService.connect();

  stdout.writeln('Creating Atlas Vector Search index "$indexName" on "${Collections.embeddings}"...');
  try {
    final result = await mongo.db.runCommand({
      'createSearchIndexes': Collections.embeddings,
      'indexes': [
        {
          'name': indexName,
          'type': 'vectorSearch',
          'definition': {
            'fields': [
              {
                'type': 'vector',
                'path': 'vector',
                // text-embedding-3-small (OPENAI_EMBEDDING_MODEL) produces
                // 1536-dimensional vectors.
                'numDimensions': 1536,
                'similarity': 'cosine',
              },
            ],
          },
        },
      ],
    });
    stdout.writeln('OK: $result');
    stdout.writeln('');
    stdout.writeln('Index build is asynchronous on Atlas — it may take a minute or two to '
        'become queryable. Check status in the Atlas UI (Database > Search) or just retry '
        'a search after a short wait.');
  } catch (e) {
    stderr.writeln('Failed: $e');
    stderr.writeln('');
    stderr.writeln('If this says the index already exists, that\'s fine — nothing to do.');
    exitCode = 1;
  }

  await mongo.close();
}
