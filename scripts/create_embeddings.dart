// Creates vector embeddings for generated sentences and stores them in the
// `embeddings` collection, keyed to `sanskrit_sentences` by _id (spec §17,
// §26). Requires EMBEDDING_MODEL to be set to a real model in .env — until
// then this exits with a clear message rather than silently doing nothing
// or faking vectors.
//
// Usage: dart run create_embeddings.dart [--limit 500]
//
// This does NOT set up the Atlas Vector Search index itself (that's a
// one-time Atlas UI/CLI step outside this repo's scope) — it only populates
// the `embeddings` collection. VectorSearchService stays a no-op until both
// this has run and a `VECTOR_INDEX_NAME` index exists on the collection.

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/config/env_config.dart';
import 'package:dart_frog_api/src/db/mongo_client.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';

Future<void> main(List<String> arguments) async {
  final env = EnvConfig.instance;
  final embeddingModel = env.getOrDefault('EMBEDDING_MODEL', '');
  if (embeddingModel.isEmpty || embeddingModel.startsWith('<YOUR_')) {
    stderr.writeln(
      'EMBEDDING_MODEL is not configured in .env — set it to a real '
      'embeddings-capable model slug before running this script. Skipping.',
    );
    exitCode = 1;
    return;
  }

  final apiKey = env.openAiApiKey;
  if (apiKey == null) {
    stderr.writeln('OPENAI_API_KEY is not configured. Skipping.');
    exitCode = 1;
    return;
  }

  final limit = int.parse(_argValue(arguments, '--limit') ?? '500');

  final mongo = await MongoClientService.connect();
  final sentences = mongo.collection(Collections.sanskritSentences);
  final embeddings = mongo.collection(Collections.embeddings);

  final toEmbed = await sentences.find(where.limit(limit)).toList();
  stdout.writeln('Embedding up to ${toEmbed.length} sentence(s) with "$embeddingModel"...');

  final client = http.Client();
  var done = 0;
  try {
    for (final doc in toEmbed) {
      final id = doc['_id'];
      final text = '${doc['sanskrit'] ?? ''}\n${doc['english'] ?? ''}';

      final response = await client.post(
        Uri.parse('${env.openAiBaseUrl}/embeddings'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({'model': embeddingModel, 'input': text}),
      );

      if (response.statusCode >= 400) {
        stderr.writeln('  ! embedding failed for $id: HTTP ${response.statusCode}');
        continue;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final vector = (decoded['data'] as List<dynamic>).first['embedding'] as List<dynamic>;

      await embeddings.replaceOne(
        where.eq('_id', id),
        {
          '_id': id,
          'source_collection': Collections.sanskritSentences,
          'model': embeddingModel,
          'vector': vector,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        upsert: true,
      );
      done++;
      if (done % 20 == 0) stdout.writeln('  ...$done embedded');
    }
  } finally {
    client.close();
    await mongo.close();
  }

  stdout.writeln('Done. Embedded $done sentence(s) into "${Collections.embeddings}".');
  stdout.writeln('Remember to create the Atlas Vector Search index (VECTOR_INDEX_NAME) '
      'on that collection before VectorSearchService can use it.');
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
