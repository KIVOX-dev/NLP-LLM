import '../config/env_config.dart';

enum LlmTaskType { simpleDictionary, translation, complexAnalysis }

/// Chooses which configured model a request should use, per spec §51.
/// Kept intentionally simple (env-driven) so routing policy can change
/// without touching call sites.
class ModelRouter {
  ModelRouter(this._env);

  final EnvConfig _env;

  String modelFor(LlmTaskType task) {
    switch (task) {
      case LlmTaskType.simpleDictionary:
        return _env.openAiEconomyModel;
      case LlmTaskType.translation:
        return _env.openAiModel;
      case LlmTaskType.complexAnalysis:
        return _env.openAiModel;
    }
  }
}
