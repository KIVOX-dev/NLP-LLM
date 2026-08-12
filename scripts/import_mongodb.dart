// Loads validated dataset JSONL into MongoDB so the existing retrieval/RAG
// pipeline (VectorSearchService, VocabularyRepository) has real data to work
// with (spec §16, §17). Idempotent: every write is an upsert keyed by a
// deterministic _id, so re-running after generating more examples just
// tops up the collections rather than duplicating documents.
//
// Usage: dart run import_mongodb.dart [--dir ../dataset]
//
// Populates:
//   sanskrit_sentences  — one doc per generated example (train/validation/
//                          test/evaluation), the corpus VectorSearchService
//                          will eventually embed and search over.
//   sanskrit_words       — vocabulary aggregated by lemma from every
//                          example's word analysis (feeds VocabularyRepository).
//   training_examples    — the same sentences reshaped into the
//                          {"messages": [...]} fine-tuning format (spec §27),
//                          metadata preserved alongside rather than discarded.

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/db/mongo_client.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'lib/mongo_retry.dart';

Future<void> main(List<String> arguments) async {
  final dirArg = _argValue(arguments, '--dir') ?? '../dataset';
  final rootDir = Directory(dirArg).existsSync() ? dirArg : _fallbackDir();

  stdout.writeln('Connecting to MongoDB...');
  final writer = MongoRetryWriter(await MongoClientService.connect());
  stdout.writeln('Connected to database "${writer.mongo.db.databaseName}".');

  var sentenceCount = 0;
  var trainingCount = 0;
  final vocabByLemma = <String, Map<String, dynamic>>{};

  for (final split in const ['train', 'validation', 'test', 'evaluation']) {
    final path = split == 'evaluation'
        ? '$rootDir/evaluation/difficult_cases.jsonl'
        : '$rootDir/translation/$split.jsonl';
    final file = File(path);
    if (!file.existsSync()) continue;

    for (final line in file.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      final row = jsonDecode(line) as Map<String, dynamic>;
      final id = row['id'] as String;

      await writer.write(
        (mongo) => mongo.collection(Collections.sanskritSentences).replaceOne(
              where.eq('_id', id),
              {'_id': id, ...row, 'split': split},
              upsert: true,
            ),
      );
      sentenceCount++;

      await writer.write(
        (mongo) => mongo.collection(Collections.trainingExamples).replaceOne(
              where.eq('_id', id),
              {
                '_id': id,
                'split': split,
                'source_type': row['source_type'],
                'verified': row['verified'],
                'messages': [
                  {'role': 'user', 'content': row['sanskrit']},
                  {
                    'role': 'assistant',
                    'content': jsonEncode({
                      'iast': row['iast'],
                      'english': row['english'],
                      'tamil': row['tamil'],
                      'grammar': row['grammar'],
                      'sandhi': row['sandhi'],
                      'compounds': row['compounds'],
                    }),
                  },
                ],
              },
              upsert: true,
            ),
      );
      trainingCount++;

      for (final w in (row['words'] as List<dynamic>? ?? const [])) {
        final word = w as Map<String, dynamic>;
        final morphology = word['morphology'] as Map<String, dynamic>?;
        final lemma = morphology?['lemma'] as String? ?? word['surface'] as String?;
        if (lemma == null) continue;

        final entry = vocabByLemma.putIfAbsent(
          lemma,
          () => {
            'lemma': lemma,
            'iast': word['iast'],
            'pos': morphology?['part_of_speech'],
            'gender': morphology?['gender'],
            'surface_forms': <String>{},
            'english_meanings': <String>{},
            'tamil_meanings': <String>{},
            'source_type': 'synthetic',
            'verified': false,
          },
        );
        (entry['surface_forms'] as Set<String>).add(word['surface'] as String? ?? '');
        if (word['english_meaning'] != null) {
          (entry['english_meanings'] as Set<String>).add(word['english_meaning'] as String);
        }
        if (word['tamil_meaning'] != null) {
          (entry['tamil_meanings'] as Set<String>).add(word['tamil_meaning'] as String);
        }
      }
    }
  }

  var vocabCount = 0;
  for (final entry in vocabByLemma.values) {
    final id = entry['lemma'] as String;
    await writer.write(
      (mongo) => mongo.collection(Collections.sanskritWords).replaceOne(
            where.eq('_id', id),
            {
              '_id': id,
              'lemma': entry['lemma'],
              'iast': entry['iast'],
              'pos': entry['pos'],
              'gender': entry['gender'],
              'surface_forms': (entry['surface_forms'] as Set<String>).where((s) => s.isNotEmpty).toList(),
              'english_meanings': (entry['english_meanings'] as Set<String>).toList(),
              'tamil_meanings': (entry['tamil_meanings'] as Set<String>).toList(),
              'domains': <String>[],
              'source_type': entry['source_type'],
              'verified': entry['verified'],
            },
            upsert: true,
          ),
    );
    vocabCount++;
  }

  stdout.writeln('');
  stdout.writeln('Imported $sentenceCount sentence(s) into "${Collections.sanskritSentences}".');
  stdout.writeln('Imported $trainingCount training example(s) into "${Collections.trainingExamples}".');
  stdout.writeln('Upserted $vocabCount vocabulary entr${vocabCount == 1 ? 'y' : 'ies'} into "${Collections.sanskritWords}".');
  stdout.writeln('All records are source_type=synthetic, verified=false until reviewed (spec §25).');

  await writer.mongo.close();
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

String _fallbackDir() {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  return '$scriptDir${Platform.pathSeparator}..${Platform.pathSeparator}dataset';
}
