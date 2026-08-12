/// Validates the raw JSON object returned by the LLM against the shape
/// mandated by the master system prompt (spec §19, §20). `response_format:
/// json_object` only guarantees syntactically valid JSON — this is the
/// schema check on top of that. Returns a list of problems; empty means
/// valid. Callers decide what to do with problems (reject / retry / degrade
/// confidence) — this class never mutates or "fixes" the data itself.
class TranslationValidator {
  const TranslationValidator();

  static const _requiredStringFields = ['source', 'english', 'tamil'];
  static const _optionalStringFields = ['iast', 'literal_english', 'literal_tamil'];
  static const _listFields = ['word_analysis', 'sandhi', 'compounds', 'uncertainties'];

  List<String> validate(Map<String, dynamic> json) {
    final problems = <String>[];

    for (final field in _requiredStringFields) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        problems.add('missing or empty required field "$field"');
      }
    }

    for (final field in _optionalStringFields) {
      final value = json[field];
      if (value != null && value is! String) {
        problems.add('field "$field" must be a string when present');
      }
    }

    for (final field in _listFields) {
      final value = json[field];
      if (value != null && value is! List) {
        problems.add('field "$field" must be an array when present');
      }
    }

    if (json['grammar'] != null && json['grammar'] is! Map) {
      problems.add('field "grammar" must be an object when present');
    }

    if (json['pronunciation'] != null && json['pronunciation'] is! Map) {
      problems.add('field "pronunciation" must be an object when present');
    }

    if (json['confidence'] != null && json['confidence'] is! Map) {
      problems.add('field "confidence" must be an object when present');
    }

    final wordAnalysis = json['word_analysis'];
    if (wordAnalysis is List) {
      for (var i = 0; i < wordAnalysis.length; i++) {
        final entry = wordAnalysis[i];
        if (entry is! Map) {
          problems.add('word_analysis[$i] must be an object');
          continue;
        }
        if (entry['surface'] is! String) {
          problems.add('word_analysis[$i].surface must be a string');
        }
      }
    }

    return problems;
  }

  bool isValid(Map<String, dynamic> json) => validate(json).isEmpty;
}
