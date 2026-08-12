/// Single place to rebrand the app (spec §1: "Use the temporary project
/// name... Make the name configurable so it can later be changed") and to
/// configure the backend URL per build.
abstract final class AppConfig {
  /// Working product name — change this one constant to rebrand.
  static const String appName = 'SanskritAI Translator';

  static const String appTagline =
      'Translate Sanskrit into English and Tamil with linguistic analysis.';

  /// Never hardcode a production URL (spec §57). Override per build with:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  /// Defaults to a local Dart Frog dev server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const Duration apiTimeout = Duration(seconds: 30);
}
