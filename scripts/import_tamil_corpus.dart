// Imports a bounded sample of clean Tamil sentences extracted from a
// Wikipedia XML-ish dump (Kaggle: younusmohamed/tamil-tamizh-wikipedia-articles)
// into a standalone reference collection. NOT paired with any Sanskrit
// sentence — this is monolingual Tamil text for future vocabulary/embedding
// work, not a source of translation examples on its own.
//
// Usage: dart run import_tamil_corpus.dart --file <path> --limit 200

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
  final sourceName =
      _argValue(arguments, '--source-name') ?? 'younusmohamed/tamil-tamizh-wikipedia-articles (Kaggle, CC-BY-SA-3.0)';

  if (filePath == null) {
    stderr.writeln('Usage: dart run import_tamil_corpus.dart --file <path> [--limit 200]');
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

  final lines = file.openRead().transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter());
  await for (final rawLine in lines) {
    if (selected.length >= limit) break;
    final cleaned = _clean(rawLine);
    if (cleaned == null) continue;
    if (!seen.add(cleaned)) continue;
    selected.add(cleaned);
  }

  stdout.writeln('Selected ${selected.length} clean Tamil sentence(s). Connecting to MongoDB...');
  final writer = MongoRetryWriter(await MongoClientService.connect());

  var inserted = 0;
  for (final tamil in selected) {
    final id = 'corpus-${_uuid.v5(Namespace.url.value, tamil)}';
    await writer.write(
      (mongo) => mongo.collection(Collections.tamilCorpusSentences).replaceOne(
            where.eq('_id', id),
            {'_id': id, 'tamil': tamil, 'source_type': 'corpus', 'source_name': sourceName, 'verified': false},
            upsert: true,
          ),
    );
    inserted++;
  }

  stdout.writeln('Upserted $inserted sentence(s) into "${Collections.tamilCorpusSentences}".');
  await writer.mongo.close();
}

/// Strips <doc>/</doc> wrapper tags, wiki markup ([[links]], '' / ''' emphasis,
/// {{templates}}), unescapes HTML entities, and rejects lines that are too
/// short, too long, markup-only, or contain no actual Tamil script.
String? _clean(String rawLine) {
  var line = rawLine.trim();
  if (line.isEmpty) return null;
  if (line.startsWith('<doc') || line.startsWith('</doc>')) return null;
  if (line.startsWith('{{') || line.startsWith(';')) return null;

  line = line.replaceAll(RegExp(r'\{\{[^}]*\}\}'), '');
  line = line.replaceAll(RegExp(r'\[\[([^|\]]*\|)?([^\]]*)\]\]'), r'$2');
  line = line.replaceAll("'''", '').replaceAll("''", '');
  line = line
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'");
  line = line.trim();

  if (line.length < 15 || line.length > 400) return null;
  if (!line.runes.any((cp) => cp >= 0x0B80 && cp <= 0x0BFF)) return null; // Tamil Unicode block
  return line;
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
