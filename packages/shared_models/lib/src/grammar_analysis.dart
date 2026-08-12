/// Sentence-level grammar summary (subject/object/verb + tense/person/number),
/// shown in the "Grammar" section of the chat UI. Word-level morphological
/// detail lives on each `WordAnalysis.morphology` instead.
class GrammarAnalysis {
  const GrammarAnalysis({
    this.subject,
    this.object,
    this.verb,
    this.tense,
    this.person,
    this.number,
    this.voice,
    this.mood,
    this.notes = const [],
  });

  final String? subject;
  final String? object;
  final String? verb;
  final String? tense;
  final String? person;
  final String? number;
  final String? voice;
  final String? mood;
  final List<String> notes;

  bool get isEmpty =>
      subject == null &&
      object == null &&
      verb == null &&
      tense == null &&
      person == null &&
      number == null &&
      voice == null &&
      mood == null;

  factory GrammarAnalysis.fromJson(Map<String, dynamic> json) => GrammarAnalysis(
        subject: json['subject'] as String?,
        object: json['object'] as String?,
        verb: json['verb'] as String?,
        tense: json['tense'] as String?,
        person: json['person'] as String?,
        number: json['number'] as String?,
        voice: json['voice'] as String?,
        mood: json['mood'] as String?,
        notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        if (subject != null) 'subject': subject,
        if (object != null) 'object': object,
        if (verb != null) 'verb': verb,
        if (tense != null) 'tense': tense,
        if (person != null) 'person': person,
        if (number != null) 'number': number,
        if (voice != null) 'voice': voice,
        if (mood != null) 'mood': mood,
        'notes': notes,
      };
}

enum SandhiType { vowel, consonant, visarga, anusvara }

SandhiType sandhiTypeFromString(String value) {
  switch (value) {
    case 'consonant':
      return SandhiType.consonant;
    case 'visarga':
      return SandhiType.visarga;
    case 'anusvara':
      return SandhiType.anusvara;
    case 'vowel':
    default:
      return SandhiType.vowel;
  }
}

/// One possible sandhi split. Multiple `SandhiResult`s for the same surface
/// span mean the segmentation is genuinely ambiguous — the UI must show all
/// of them rather than silently picking one.
class SandhiResult {
  const SandhiResult({
    required this.surface,
    required this.components,
    required this.type,
    this.rule,
    this.isAmbiguous = false,
  });

  final String surface;
  final List<String> components;
  final SandhiType type;
  final String? rule;
  final bool isAmbiguous;

  factory SandhiResult.fromJson(Map<String, dynamic> json) => SandhiResult(
        surface: json['surface'] as String? ?? '',
        components:
            (json['components'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        type: sandhiTypeFromString(json['type'] as String? ?? 'vowel'),
        rule: json['rule'] as String?,
        isAmbiguous: json['is_ambiguous'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'components': components,
        'type': type.name,
        if (rule != null) 'rule': rule,
        'is_ambiguous': isAmbiguous,
      };
}

enum SamasaType { tatpurusha, karmadharaya, bahuvrihi, dvandva, avyayibhava, unknown }

SamasaType samasaTypeFromString(String? value) {
  switch (value) {
    case 'tatpurusha':
      return SamasaType.tatpurusha;
    case 'karmadharaya':
      return SamasaType.karmadharaya;
    case 'bahuvrihi':
      return SamasaType.bahuvrihi;
    case 'dvandva':
      return SamasaType.dvandva;
    case 'avyayibhava':
      return SamasaType.avyayibhava;
    default:
      return SamasaType.unknown;
  }
}

/// Compound (samāsa) analysis. `type` is `unknown` when the classifier isn't
/// confident — the platform must not force a classification (see spec §15).
class CompoundResult {
  const CompoundResult({
    required this.surface,
    required this.members,
    this.type = SamasaType.unknown,
    this.gloss,
  });

  final String surface;
  final List<String> members;
  final SamasaType type;
  final String? gloss;

  factory CompoundResult.fromJson(Map<String, dynamic> json) => CompoundResult(
        surface: json['surface'] as String? ?? '',
        members: (json['members'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        type: samasaTypeFromString(json['type'] as String?),
        gloss: json['gloss'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'members': members,
        'type': type.name,
        if (gloss != null) 'gloss': gloss,
      };
}

/// Vedic accent metadata. Treated as authoritative-or-absent: never inferred
/// from plain Devanagari (see spec §22). `accent` is null unless a verified
/// accented source is available.
class AccentInfo {
  const AccentInfo({
    this.accentSystem,
    this.udatta,
    this.anudatta,
    this.svarita,
    this.source,
    this.confidence,
  });

  final String? accentSystem;
  final List<int>? udatta;
  final List<int>? anudatta;
  final List<int>? svarita;
  final String? source;
  final String? confidence;

  factory AccentInfo.fromJson(Map<String, dynamic> json) => AccentInfo(
        accentSystem: json['accent_system'] as String?,
        udatta: (json['udatta'] as List<dynamic>?)?.map((e) => e as int).toList(),
        anudatta: (json['anudatta'] as List<dynamic>?)?.map((e) => e as int).toList(),
        svarita: (json['svarita'] as List<dynamic>?)?.map((e) => e as int).toList(),
        source: json['source'] as String?,
        confidence: json['confidence'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (accentSystem != null) 'accent_system': accentSystem,
        if (udatta != null) 'udatta': udatta,
        if (anudatta != null) 'anudatta': anudatta,
        if (svarita != null) 'svarita': svarita,
        if (source != null) 'source': source,
        if (confidence != null) 'confidence': confidence,
      };
}

class PronunciationResult {
  const PronunciationResult({
    required this.original,
    required this.iast,
    required this.syllables,
    this.guide,
    this.accent,
  });

  final String original;
  final String iast;

  /// Syllabified IAST, e.g. ["gac", "cha", "ti"].
  final List<String> syllables;

  /// Hyphenated pronunciation guide, e.g. "gac-cha-ti".
  final String? guide;

  final AccentInfo? accent;

  factory PronunciationResult.fromJson(Map<String, dynamic> json) => PronunciationResult(
        original: json['original'] as String? ?? '',
        iast: json['iast'] as String? ?? '',
        syllables: (json['syllables'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        guide: json['guide'] as String?,
        accent: json['accent'] == null ? null : AccentInfo.fromJson(json['accent'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'original': original,
        'iast': iast,
        'syllables': syllables,
        if (guide != null) 'guide': guide,
        'accent': accent?.toJson(),
      };
}
