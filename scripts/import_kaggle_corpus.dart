// Imports a bounded sample of REAL (not LLM-generated) Sanskrit sentences
// from a raw corpus file into the sanskrit_sentences collection, tagged
// source_type=corpus (distinct from source_type=synthetic used by
// generate_dataset.dart). These are untranslated — english/tamil are null
// until either a human or the translation pipeline fills them in — this
// script only grounds the corpus text itself, it never fabricates a
// translation for it (spec §53/§57: don't claim authority you don't have).
//
// Usage: dart run import_kaggle_corpus.dart --file <path> --limit 200 --source-name "..."

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/db/mongo_client.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

import 'lib/mongo_retry.dart';

const _uuid = Uuid();

Future<void> main(List<String> arguments) async {
  final filePath = _argValue(arguments, '--file');
  final limit = int.parse(_argValue(arguments, '--limit') ?? '200');
  final sourceName = _argValue(arguments, '--source-name') ?? 'unknown';

  if (filePath == null) {
    stderr.writeln('Usage: dart run import_kaggle_corpus.dart --file <path> [--limit 200] [--source-name "..."]');
    exitCode = 1;
    return;
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $filePath');
    exitCode = 1;
    return;
  }

  stdout.writeln('Reading up to $limit clean lines from $filePath ...');
  final seen = <String>{};
  final selected = <String>[];

  // Read line-by-line rather than loading the whole (potentially large) file.
  final lines = file.openRead().transform(utf8.decoder, ).transform(const LineSplitter());
  await for (final rawLine in lines) {
    if (selected.length >= limit) break;
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.length < 8 || line.length > 300) continue; // skip fragments/outliers
    if (!_containsDevanagari(line)) continue;
    if (!seen.add(line)) continue; // dedupe
    selected.add(line);
  }

  stdout.writeln('Selected ${selected.length} unique Sanskrit line(s). Connecting to MongoDB...');
  final writer = MongoRetryWriter(await MongoClientService.connect());

  var inserted = 0;
  for (final sanskrit in selected) {
    final id = 'corpus-${_uuid.v5(Namespace.url.value, sanskrit)}';
    await writer.write(
      (mongo) => mongo.collection(Collections.sanskritSentences).replaceOne(
            where.eq('_id', id),
            {
              '_id': id,
              'sanskrit': sanskrit,
              'english': null,
              'tamil': null,
              'source_type': 'corpus',
              'source_name': sourceName,
              'verified': false,
            },
            upsert: true,
          ),
    );
    inserted++;
  }

  stdout.writeln('Upserted $inserted corpus sentence(s) into "${Collections.sanskritSentences}" '
      '(source_type=corpus, untranslated, source_name="$sourceName").');
  await writer.mongo.close();
}

bool _containsDevanagari(String text) => text.runes.any((cp) => cp >= 0x0900 && cp <= 0x097F);

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
