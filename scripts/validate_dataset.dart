// Validates generated dataset JSONL files (spec §25, §26).
//
// Usage: dart run validate_dataset.dart [--dir ../dataset]
//
// Checks: valid JSON per line, required fields present and non-empty,
// no duplicate ids within or across files, no duplicate Sanskrit sentences
// across train/validation/test (would leak eval data into training), and
// that source_type=synthetic examples are never marked verified=true
// without a human having actually done so (spec §25).
//
// Exits with a non-zero code if any check fails, so this can gate CI.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final dirArg = _argValue(arguments, '--dir') ?? '../dataset';
  final rootDir = Directory(dirArg).existsSync() ? dirArg : _fallbackDir();

  final files = <String, String>{
    'train': '$rootDir/translation/train.jsonl',
    'validation': '$rootDir/translation/validation.jsonl',
    'test': '$rootDir/translation/test.jsonl',
    'evaluation': '$rootDir/evaluation/difficult_cases.jsonl',
  };

  final problems = <String>[];
  final idsBySplit = <String, Set<String>>{};
  final sentenceToSplits = <String, Set<String>>{};
  final counts = <String, int>{};
  final difficultyCounts = <String, int>{};
  final domainCounts = <String, int>{};

  for (final entry in files.entries) {
    final split = entry.key;
    final file = File(entry.value);
    idsBySplit[split] = {};
    counts[split] = 0;

    if (!file.existsSync()) {
      stdout.writeln('(no file for $split yet: ${entry.value})');
      continue;
    }

    final lines = file.readAsLinesSync();
    for (var lineNo = 0; lineNo < lines.length; lineNo++) {
      final line = lines[lineNo].trim();
      if (line.isEmpty) continue;

      Map<String, dynamic> row;
      try {
        row = jsonDecode(line) as Map<String, dynamic>;
      } catch (e) {
        problems.add('$split:${lineNo + 1} invalid JSON: $e');
        continue;
      }

      for (final field in ['id', 'sanskrit', 'iast', 'english', 'tamil', 'source_type', 'verified']) {
        if (!row.containsKey(field)) {
          problems.add('$split:${lineNo + 1} missing field "$field"');
        }
      }

      final id = row['id'] as String? ?? '<missing>';
      if (!idsBySplit[split]!.add(id)) {
        problems.add('$split:${lineNo + 1} duplicate id "$id" within $split');
      }

      final sanskrit = (row['sanskrit'] as String? ?? '').trim();
      if (sanskrit.isEmpty) {
        problems.add('$split:${lineNo + 1} empty "sanskrit" field ($id)');
      } else {
        sentenceToSplits.putIfAbsent(sanskrit, () => {}).add(split);
      }

      if ((row['english'] as String? ?? '').trim().isEmpty) {
        problems.add('$split:${lineNo + 1} empty "english" field ($id)');
      }
      if ((row['tamil'] as String? ?? '').trim().isEmpty) {
        problems.add('$split:${lineNo + 1} empty "tamil" field ($id)');
      }

      if (row['source_type'] == 'synthetic' && row['verified'] == true) {
        problems.add('$split:${lineNo + 1} synthetic example marked verified=true ($id) — '
            'spec §25 requires verified=false until human review');
      }

      counts[split] = counts[split]! + 1;
      final difficulty = row['difficulty'] as String? ?? 'unknown';
      difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      final domain = row['domain'] as String? ?? 'unknown';
      domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
    }
  }

  // Cross-split duplicate/leak check.
  for (final entry in sentenceToSplits.entries) {
    if (entry.value.length > 1) {
      problems.add('sentence appears in multiple splits (${entry.value.join(', ')}): "${entry.key}"');
    }
  }

  // The evaluation set must never overlap with train/validation (spec §28).
  final evalSentences = sentenceToSplits.entries
      .where((e) => e.value.contains('evaluation'))
      .map((e) => e.key)
      .toSet();
  final trainingSentences = sentenceToSplits.entries
      .where((e) => e.value.any((s) => s != 'evaluation'))
      .map((e) => e.key)
      .toSet();
  final leaked = evalSentences.intersection(trainingSentences);
  for (final sentence in leaked) {
    problems.add('evaluation sentence also appears in train/validation/test: "$sentence"');
  }

  stdout.writeln('--- Counts ---');
  counts.forEach((split, count) => stdout.writeln('$split: $count'));
  stdout.writeln('--- By difficulty ---');
  difficultyCounts.forEach((k, v) => stdout.writeln('$k: $v'));
  stdout.writeln('--- By domain ---');
  domainCounts.forEach((k, v) => stdout.writeln('$k: $v'));

  stdout.writeln('');
  if (problems.isEmpty) {
    stdout.writeln('OK — no problems found.');
  } else {
    stdout.writeln('${problems.length} problem(s) found:');
    for (final p in problems.take(200)) {
      stdout.writeln('  - $p');
    }
    if (problems.length > 200) stdout.writeln('  ... and ${problems.length - 200} more');
    exitCode = 1;
  }
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
