// Generates dataset examples via the configured LLM (spec §23-§26).
//
// Usage (run from anywhere in the repo; it resolves .env on its own — see
// EnvConfig._findEnvFile):
//   dart run generate_dataset.dart --count 20            # small pilot
//   dart run generate_dataset.dart --count 5000           # full dataset
//   dart run generate_dataset.dart --count 200 --category verbs
//
// Every example is written with source_type=synthetic, verified=false
// (spec §25) — nothing here is ever marked authoritative. Output is
// appended, not overwritten, and each example's id is deterministic
// ("<category>-<index>"), so re-running with a higher --count safely tops
// up an existing run instead of duplicating it.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_frog_api/src/config/env_config.dart';
import 'package:dart_frog_api/src/core/errors/app_exception.dart';
import 'package:dart_frog_api/src/llm/llm_provider.dart';

import 'lib/dataset_example.dart';
import 'lib/rotating_llm_provider.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('count', defaultsTo: '20', help: 'Total examples to generate across all categories.')
    ..addOption('category', help: 'Only generate this one category (see lib/dataset_example.dart).')
    ..addOption('delay-ms', defaultsTo: '400', help: 'Delay between LLM calls, per key.')
    ..addOption('out-dir', defaultsTo: '../dataset', help: 'Dataset root (relative to this script by default).')
    ..addFlag('help', abbr: 'h', negatable: false);

  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }

  final requestedTotal = int.parse(args['count'] as String);
  final categoryFilter = args['category'] as String?;
  final delay = Duration(milliseconds: int.parse(args['delay-ms'] as String));
  final outDir = _resolveOutDir(args['out-dir'] as String);

  final apiKeys = EnvConfig.instance.openAiApiKeys;
  if (apiKeys.isEmpty) {
    stderr.writeln('No API keys configured. Set OPENAI_API_KEY or OPENAI_API_KEYS in .env.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Using ${apiKeys.length} API key(s) in rotation, model=${EnvConfig.instance.openAiEconomyModel}');

  final provider = RotatingLlmProvider(apiKeys, onEvent: (m) => stdout.writeln('[rotation] $m'));

  final categories = categoryFilter == null
      ? datasetDistribution
      : datasetDistribution.where((c) => c.name == categoryFilter).toList();
  if (categories.isEmpty) {
    stderr.writeln('Unknown category "$categoryFilter". Valid: ${datasetDistribution.map((c) => c.name).join(', ')}');
    exitCode = 1;
    return;
  }

  final totalInDistribution = categories.fold<int>(0, (sum, c) => sum + c.targetCount);
  final scale = requestedTotal / (categoryFilter == null ? datasetDistributionTotal : totalInDistribution);

  final sink = _DatasetSink(outDir);
  var generated = 0;
  var failed = 0;
  final overallStart = DateTime.now();

  for (final category in categories) {
    final allocation = categoryFilter == null
        ? (category.targetCount * scale).round().clamp(0, category.targetCount)
        : requestedTotal;
    if (allocation <= 0) continue;

    final startIndex = sink.countExistingForCategory(category.name);
    stdout.writeln('--- ${category.name} (domain=${category.domain}): generating $allocation, '
        'starting at index $startIndex ---');

    for (var i = 0; i < allocation; i++) {
      final index = startIndex + i;
      final id = '${category.name}-${index.toString().padLeft(4, '0')}';

      try {
        final result = await provider.generateTrainingExample(
          LlmTranslationContext(
            sanskritText: '',
            targetLanguageCodes: const ['en', 'ta'],
            generationBrief: DatasetGenerationBrief(
              category: category.name,
              domain: category.domain,
              guidance: category.guidance,
            ),
          ),
        );

        final example = _toDatasetExample(id, category, result.json);
        sink.write(example);
        generated++;
        stdout.writeln('[$generated] $id  ${example.sanskrit}');
      } catch (e) {
        failed++;
        final detail = e is AppException ? '${e.code}: ${e.message}' : e.toString();
        stderr.writeln('  ! failed $id: $detail');
      }

      if (delay > Duration.zero) await Future<void>.delayed(delay);
    }
  }

  sink.close();

  final elapsed = DateTime.now().difference(overallStart);
  stdout.writeln('');
  stdout.writeln('Done in ${elapsed.inSeconds}s. Generated: $generated, failed: $failed.');
  stdout.writeln('Run validate_dataset.dart next, then import_mongodb.dart.');
}

DatasetExample _toDatasetExample(String id, DatasetCategory category, Map<String, dynamic> json) {
  return DatasetExample(
    id: id,
    sanskrit: json['sanskrit'] as String? ?? '',
    iast: json['iast'] as String? ?? '',
    english: json['english'] as String? ?? '',
    tamil: json['tamil'] as String? ?? '',
    words: ((json['words'] as List<dynamic>?) ?? const []).whereType<Map<String, dynamic>>().toList(),
    grammar: (json['grammar'] as Map<String, dynamic>?) ?? const {},
    sandhi: ((json['sandhi'] as List<dynamic>?) ?? const []).whereType<Map<String, dynamic>>().toList(),
    compounds: ((json['compounds'] as List<dynamic>?) ?? const []).whereType<Map<String, dynamic>>().toList(),
    domain: category.domain,
    difficulty: json['difficulty'] as String? ?? (category.name == 'difficult_evaluation' ? 'hard' : 'medium'),
    sourceType: 'synthetic',
    verified: false,
  );
}

String _resolveOutDir(String configured) {
  if (Directory(configured).existsSync()) return configured;
  // Fall back to a path relative to this script's own location, so the
  // script works when invoked from a different cwd (spec §26: "must be
  // independently runnable").
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final fallback = '$scriptDir${Platform.pathSeparator}..${Platform.pathSeparator}dataset';
  return Directory(fallback).existsSync() ? fallback : configured;
}

/// Appends generated examples to the right JSONL file(s): the
/// train/validation/test split for normal categories, evaluation for
/// difficult_evaluation, plus derived vocabulary/morphology/sandhi extracts.
class _DatasetSink {
  _DatasetSink(this.rootDir) {
    Directory('$rootDir/translation').createSync(recursive: true);
    Directory('$rootDir/evaluation').createSync(recursive: true);
    Directory('$rootDir/vocabulary').createSync(recursive: true);
    Directory('$rootDir/morphology').createSync(recursive: true);
    Directory('$rootDir/sandhi').createSync(recursive: true);

    _train = File('$rootDir/translation/train.jsonl').openWrite(mode: FileMode.append);
    _validation = File('$rootDir/translation/validation.jsonl').openWrite(mode: FileMode.append);
    _test = File('$rootDir/translation/test.jsonl').openWrite(mode: FileMode.append);
    _evaluation = File('$rootDir/evaluation/difficult_cases.jsonl').openWrite(mode: FileMode.append);
    _vocabulary = File('$rootDir/vocabulary/vocabulary.jsonl').openWrite(mode: FileMode.append);
    _morphology = File('$rootDir/morphology/morphology.jsonl').openWrite(mode: FileMode.append);
    _sandhi = File('$rootDir/sandhi/sandhi.jsonl').openWrite(mode: FileMode.append);
  }

  final String rootDir;
  late final IOSink _train, _validation, _test, _evaluation, _vocabulary, _morphology, _sandhi;
  int _splitCounter = 0;
  final Set<String> _seenVocab = {};

  /// So re-running the generator tops up rather than duplicates: count how
  /// many ids for this category already exist across every output file.
  int countExistingForCategory(String category) {
    var count = 0;
    for (final path in [
      '$rootDir/translation/train.jsonl',
      '$rootDir/translation/validation.jsonl',
      '$rootDir/translation/test.jsonl',
      '$rootDir/evaluation/difficult_cases.jsonl',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      for (final line in file.readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        final decoded = jsonDecode(line) as Map<String, dynamic>;
        final id = decoded['id'] as String? ?? '';
        if (id.startsWith('$category-')) count++;
      }
    }
    return count;
  }

  void write(DatasetExample example) {
    final line = '${jsonEncode(example.toJson())}\n';

    if (example.domain == 'evaluation') {
      _evaluation.write(line);
    } else {
      // Deterministic ~80/10/10 split.
      final bucket = _splitCounter % 10;
      _splitCounter++;
      if (bucket == 0) {
        _test.write(line);
      } else if (bucket == 1) {
        _validation.write(line);
      } else {
        _train.write(line);
      }
    }

    for (final word in example.words) {
      final lemma = (word['morphology'] as Map<String, dynamic>?)?['lemma'] as String? ?? word['surface'] as String?;
      if (lemma == null || !_seenVocab.add(lemma)) continue;
      _vocabulary.write('${jsonEncode({
            'lemma': lemma,
            'surface': word['surface'],
            'iast': word['iast'],
            'english_meaning': word['english_meaning'],
            'tamil_meaning': word['tamil_meaning'],
            'source_example_id': example.id,
            'source_type': 'synthetic',
            'verified': false,
          })}\n');

      final morphology = word['morphology'];
      if (morphology != null) {
        _morphology.write('${jsonEncode({
              'surface': word['surface'],
              'morphology': morphology,
              'source_example_id': example.id,
              'source_type': 'synthetic',
              'verified': false,
            })}\n');
      }
    }

    for (final sandhiEntry in example.sandhi) {
      _sandhi.write('${jsonEncode({
            ...sandhiEntry,
            'source_example_id': example.id,
            'source_type': 'synthetic',
            'verified': false,
          })}\n');
    }
  }

  void close() {
    for (final sink in [_train, _validation, _test, _evaluation, _vocabulary, _morphology, _sandhi]) {
      sink.close();
    }
  }
}
