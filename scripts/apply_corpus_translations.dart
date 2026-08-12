// Merges hand-produced English translations (translations_sanskrit_corpus.json)
// into the real Sanskrit corpus already in MongoDB, and computes iast/sandhi
// for every sentence using the actual deterministic backend NLP code
// (IastTransliterator, RuleBasedSandhiAnalyzer) — not fabricated, not an LLM
// call. Matches by exact "sanskrit" text so line-number drift can't cause a
// mismatch. Reports any translation entries that don't match a DB doc, and
// any DB docs left untranslated, rather than silently ignoring gaps.

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog_api/src/db/mongo_client.dart';
import 'package:dart_frog_api/src/nlp/iast_transliterator.dart';
import 'package:dart_frog_api/src/nlp/sandhi_analyzer.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'lib/mongo_retry.dart';

Future<void> main(List<String> arguments) async {
  final jsonPath = _argValue(arguments, '--file') ?? 'translations_sanskrit_corpus.json';
  final file = File(jsonPath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $jsonPath');
    exitCode = 1;
    return;
  }

  final translations = (jsonDecode(file.readAsStringSync()) as List<dynamic>).cast<Map<String, dynamic>>();
  final bySanskrit = <String, Map<String, dynamic>>{for (final t in translations) t['sanskrit'] as String: t};

  const iast = IastTransliterator();
  final sandhi = RuleBasedSandhiAnalyzer();

  final writer = MongoRetryWriter(await MongoClientService.connect());
  final docs = await writer.mongo
      .collection(Collections.sanskritSentences)
      .find(where.eq('source_type', 'corpus'))
      .toList();

  var updated = 0;
  var sentencesWithSandhi = 0;
  final unmatchedDocs = <String>[];

  for (final doc in docs) {
    final sanskritText = doc['sanskrit'] as String;
    final translation = bySanskrit.remove(sanskritText);
    if (translation == null) {
      unmatchedDocs.add(sanskritText);
      continue;
    }

    final sandhiResults = sandhi.analyzeSentence(sanskritText);
    if (sandhiResults.isNotEmpty) sentencesWithSandhi++;

    await writer.write(
      (mongo) => mongo.collection(Collections.sanskritSentences).updateOne(
            where.eq('_id', doc['_id']),
            modify
                .set('english', translation['english'])
                .set('iast', iast.transliterate(sanskritText))
                .set('translation_confidence', translation['confidence'])
                .set('translation_note', translation['note'])
                .set('translation_source', 'claude_direct_unverified')
                .set(
                  'sandhi',
                  sandhiResults
                      .map((s) => {
                            'surface': s.surface,
                            'components': s.components,
                            'type': s.type.name,
                            'rule': s.rule,
                            'is_ambiguous': s.isAmbiguous,
                          })
                      .toList(),
                ),
          ),
    );
    updated++;
  }

  stdout.writeln('Updated $updated document(s) with english + iast + sandhi.');
  stdout.writeln('$sentencesWithSandhi sentence(s) had a detectable rule-based sandhi split (most will have none — that is correct, not a gap).');
  if (unmatchedDocs.isNotEmpty) {
    stdout.writeln('${unmatchedDocs.length} DB doc(s) had NO matching translation entry:');
    for (final s in unmatchedDocs.take(20)) {
      stdout.writeln('  - $s');
    }
  }
  if (bySanskrit.isNotEmpty) {
    stdout.writeln('${bySanskrit.length} translation entr(ies) did NOT match any DB doc (stale/typo?):');
    for (final s in bySanskrit.keys.take(20)) {
      stdout.writeln('  - $s');
    }
  }

  await writer.mongo.close();
}

String? _argValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
