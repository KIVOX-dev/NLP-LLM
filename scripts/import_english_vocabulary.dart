// Imports a bounded sample of English words into a standalone reference
// collection. NOT paired with any Sanskrit sentence — this is a monolingual
// word list (Kaggle: bwandowando/479k-english-words), useful later for
// English-side vocabulary lookups, not a source of translation examples.
//
// Usage: dart run import_english_vocabulary.dart --file <path> --limit 500

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/db/mongo_client.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'lib/mongo_retry.dart';

Future<void> main(List<String> arguments) async {
  final filePath = _argValue(arguments, '--file');
  final limit = int.parse(_argValue(arguments, '--limit') ?? '500');
  final sourceName = _argValue(arguments, '--source-name') ?? 'bwandowando/479k-english-words (Kaggle, CC0-1.0)';

  if (filePath == null) {
    stderr.writeln('Usage: dart run import_english_vocabulary.dart --file <path> [--limit 500]');
    exitCode = 1;
    return;
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $filePath');
    exitCode = 1;
    return;
  }

  final seen = <String>{};
  final selected = <String>[];
  final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
  await for (final rawLine in lines) {
    if (selected.length >= limit) break;
    final word = rawLine.trim().toLowerCase();
    if (word.isEmpty || word.length < 2) continue;
    if (!RegExp(r'^[a-z]+$').hasMatch(word)) continue;
    if (!seen.add(word)) continue;
    selected.add(word);
  }

  stdout.writeln('Selected ${selected.length} word(s). Connecting to MongoDB...');
  final writer = MongoRetryWriter(await MongoClientService.connect());

  var inserted = 0;
  for (final word in selected) {
    await writer.write(
      (mongo) => mongo.collection(Collections.englishVocabulary).replaceOne(
            where.eq('_id', word),
            {'_id': word, 'word': word, 'source_type': 'corpus', 'source_name': sourceName, 'verified': false},
            upsert: true,
          ),
    );
    inserted++;
    if (inserted % 50 == 0) stdout.writeln('  ...$inserted upserted');
  }

  stdout.writeln('Upserted $inserted word(s) into "${Collections.englishVocabulary}".');
  await writer.mongo.close();
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
