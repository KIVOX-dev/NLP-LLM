import 'dart:io';

/// Loads configuration from `.env` (repo-local, gitignored) with real process
/// environment variables taking precedence — so a container/host env var
/// always wins over a checked-out `.env` file. No secrets ever have a
/// hardcoded default; missing required values fail fast at startup.
class EnvConfig {
  EnvConfig._(this._values);

  static EnvConfig? _instance;

  static EnvConfig get instance => _instance ??= EnvConfig._(_load());

  final Map<String, String> _values;

  static Map<String, String> _load() {
    final values = <String, String>{};

    final envFile = _findEnvFile();
    if (envFile != null) {
      for (final rawLine in envFile.readAsLinesSync()) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final separator = line.indexOf('=');
        if (separator == -1) continue;
        final key = line.substring(0, separator).trim();
        var value = line.substring(separator + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        values[key] = value;
      }
    }

    // Real process env wins over .env file contents.
    values.addAll(Platform.environment);
    return values;
  }

  /// Resolves `.env` regardless of whether the current process was started
  /// from `server/dart_frog_api/` (normal `dart_frog dev` usage) or from
  /// `scripts/` or the repo root (the dataset generator scripts, which
  /// import this same config rather than duplicating env-loading logic —
  /// spec §26 requires those scripts to be independently runnable).
  static File? _findEnvFile() {
    final candidates = <String>[
      '.env',
      'server/dart_frog_api/.env',
      '../server/dart_frog_api/.env',
      '../../server/dart_frog_api/.env',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }

  String? _get(String key) {
    final value = _values[key];
    if (value == null) return null;
    if (value.isEmpty) return null;
    if (value.startsWith('<YOUR_') && value.endsWith('>')) return null;
    return value;
  }

  String require(String key) {
    final value = _get(key);
    if (value == null) {
      throw StateError(
        'Missing required environment variable "$key". '
        'Copy .env.example to .env in server/dart_frog_api/ and fill it in.',
      );
    }
    return value;
  }

  String getOrDefault(String key, String fallback) => _get(key) ?? fallback;

  int getIntOrDefault(String key, int fallback) {
    final raw = _get(key);
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  }

  bool getBoolOrDefault(String key, bool fallback) {
    final raw = _get(key);
    if (raw == null) return fallback;
    return raw.toLowerCase() == 'true';
  }

  String get appEnv => getOrDefault('APP_ENV', 'development');
  bool get isProduction => appEnv == 'production';

  String get mongoUri => require('MONGODB_URI');
  String get mongoDatabase => getOrDefault('MONGODB_DATABASE', 'sanskrit_translator');

  String get jwtSecret => require('JWT_SECRET');

  String get llmProvider => getOrDefault('LLM_PROVIDER', 'openai');
  String? get openAiApiKey => _get('OPENAI_API_KEY');

  /// Pool of keys for bulk/batch jobs that want to rotate past a single
  /// key's rate limit (see `KeyRotatingHttpClient` in scripts/). Falls back
  /// to the single `OPENAI_API_KEY` when `OPENAI_API_KEYS` isn't set, so
  /// the live API server (which only ever needs one key at a time) doesn't
  /// need to change.
  List<String> get openAiApiKeys {
    final raw = _get('OPENAI_API_KEYS');
    final keys = raw == null
        ? <String>[]
        : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (keys.isNotEmpty) return keys;
    final single = openAiApiKey;
    return single == null ? const [] : [single];
  }

  String get openAiModel => getOrDefault('OPENAI_MODEL', 'gpt-4o-mini');
  String get openAiEconomyModel => getOrDefault('OPENAI_ECONOMY_MODEL', openAiModel);
  String get openAiBaseUrl => getOrDefault('OPENAI_BASE_URL', 'https://api.openai.com/v1');

  int get maxInputCharacters => getIntOrDefault('MAX_INPUT_CHARACTERS', 2000);
  int get llmRequestTimeoutSeconds => getIntOrDefault('LLM_REQUEST_TIMEOUT_SECONDS', 30);
  int get llmMaxOutputTokens => getIntOrDefault('LLM_MAX_OUTPUT_TOKENS', 2000);

  List<String> get corsOrigins {
    final raw = _get('CORS_ORIGINS');
    if (raw == null) return const [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
