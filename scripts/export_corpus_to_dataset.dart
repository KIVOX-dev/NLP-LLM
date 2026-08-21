// Materializes the raw (unpaired, monolingual) corpora already imported
// into MongoDB — sanskrit_sentences (source_type=corpus), english_vocabulary,
// tamil_corpus_sentences — as JSONL files under dataset/raw_corpus/, so the
// pulled data lives in the repo's dataset/ deliverable, not only in Mongo.
//
// These are explicitly NOT dataset/translation/*.jsonl: that directory is
// reserved for genuine paired Sanskrit+English+Tamil translation examples.
// A Sanskrit verse from one book, an English dictionary word, and a random
// Tamil Wikipedia sentence have no correspondence to each other — this
// script does not invent one. It only reformats each corpus, in its own
// language, into a clean JSONL file.
//
// Usage: dart run export_corpus_to_dataset.dart [--out-dir ../dataset/raw_corpus]

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/db/mongo_client.dart';

Future<void> main(List<String> arguments) async {
  final outDirArg = _argValue(arguments, '--out-dir') ?? '../dataset/raw_corpus';
  final outDir = Directory(outDirArg).parent.existsSync() ? outDirArg : _fallbackDir();
  Directory(outDir).createSync(recursive: true);

  final mongo = await MongoClientService.connect();

  final sanskritCount = await _export(
    mongo: mongo,
    collectionName: Collections.sanskritSentences,
    filter: {'source_type': 'corpus'},
    outFile: '$outDir/sanskrit.jsonl',
    project: (doc) => {
      'sanskrit': doc['sanskrit'],
      'iast': doc['iast'],
      'english': doc['english'],
      'tamil': doc['tamil'],
      'sandhi': doc['sandhi'],
      'translation_confidence': doc['translation_confidence'],
      'translation_note': doc['translation_note'],
      'translation_source': doc['translation_source'],
      'source_type': doc['source_type'],
      'source_name': doc['source_name'],
      'verified': doc['verified'],
    },
  );

  final englishCount = await _export(
    mongo: mongo,
    collectionName: Collections.englishVocabulary,
    filter: const {},
    outFile: '$outDir/english.jsonl',
    project: (doc) => {
      'word': doc['word'],
      'source_type': doc['source_type'],
      'source_name': doc['source_name'],
      'verified': doc['verified'],
    },
  );

  final tamilCount = await _export(
    mongo: mongo,
    collectionName: Collections.tamilCorpusSentences,
    filter: const {},
    outFile: '$outDir/tamil.jsonl',
    project: (doc) => {
      'tamil': doc['tamil'],
      'source_type': doc['source_type'],
      'source_name': doc['source_name'],
      'verified': doc['verified'],
    },
  );

  stdout.writeln('Exported to $outDir:');
  stdout.writeln('  sanskrit.jsonl: $sanskritCount line(s) — untranslated, real Sanskrit corpus text');
  stdout.writeln('  english.jsonl:  $englishCount line(s) — standalone English word list');
  stdout.writeln('  tamil.jsonl:    $tamilCount line(s) — standalone Tamil sentences (Wikipedia)');
  stdout.writeln('');
  stdout.writeln('These are monolingual, unpaired corpora — not translation examples. '
      'dataset/translation/*.jsonl is unaffected and still empty.');

  await mongo.close();
}

Future<int> _export({
  required MongoClientService mongo,
  required String collectionName,
  required Map<String, dynamic> filter,
  required String outFile,
  required Map<String, dynamic> Function(Map<String, dynamic> doc) project,
}) async {
  final docs = await mongo.collection(collectionName).find(filter).toList();
  final sink = File(outFile).openWrite();
  for (final doc in docs) {
    sink.writeln(jsonEncode(project(doc)));
  }
  await sink.close();
  return docs.length;
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

String _fallbackDir() {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  return '$scriptDir${Platform.pathSeparator}..${Platform.pathSeparator}dataset${Platform.pathSeparator}raw_corpus';
}
