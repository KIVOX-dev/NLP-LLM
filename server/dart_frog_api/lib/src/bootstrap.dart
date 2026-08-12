import 'auth/jwt_service.dart';
import 'auth/password_hasher.dart';
import 'config/env_config.dart';
import 'db/mongo_client.dart';
import 'llm/llm_provider.dart';
import 'llm/openai_provider.dart';
import 'nlp/morphology_analyzer.dart';
import 'nlp/pronunciation_service.dart';
import 'nlp/samasa_analyzer.dart';
import 'nlp/sandhi_analyzer.dart';
import 'repositories/conversation_repository.dart';
import 'repositories/feedback_repository.dart';
import 'repositories/mongo_conversation_repository.dart';
import 'repositories/mongo_vocabulary_repository.dart';
import 'repositories/vocabulary_repository.dart';
import 'translation/translation_orchestrator.dart';
import 'vector/vector_search_service.dart';

/// Wires every concrete implementation behind its interface, once per
/// server process. Dart Frog route handlers are async, so async dependency
/// construction (opening the Mongo connection) is exposed as a single
/// cached `Future<AppServices>` that routes `await` via
/// `context.read<Future<AppServices>>()` — see routes/_middleware.dart.
class AppServices {
  AppServices._({
    required this.vocabularyRepository,
    required this.conversationRepository,
    required this.feedbackRepository,
    required this.llmProvider,
    required this.orchestrator,
    required this.jwtService,
    required this.passwordHasher,
  });

  final VocabularyRepository vocabularyRepository;
  final ConversationRepository conversationRepository;
  final FeedbackRepository feedbackRepository;
  final LLMProvider llmProvider;
  final TranslationOrchestrator orchestrator;
  final JwtService jwtService;
  final PasswordHasher passwordHasher;

  static Future<AppServices>? _instanceFuture;

  static Future<AppServices> instance() => _instanceFuture ??= _build();

  static Future<AppServices> _build() async {
    final mongo = await MongoClientService.connect();

    final vocabularyRepository = MongoVocabularyRepository(mongo);
    final conversationRepository = MongoConversationRepository(mongo);
    final feedbackRepository = MongoFeedbackRepository(mongo);

    final llmProvider = OpenAIProvider();

    final orchestrator = TranslationOrchestrator(
      vocabularyRepository: vocabularyRepository,
      morphologyAnalyzer: DictionaryBackedMorphologyAnalyzer(vocabularyRepository),
      sandhiAnalyzer: RuleBasedSandhiAnalyzer(),
      samasaAnalyzer: const UnknownSamasaAnalyzer(),
      pronunciationService: PronunciationService(),
      vectorSearchService: const NoOpVectorSearchService(),
      llmProvider: llmProvider,
    );

    return AppServices._(
      vocabularyRepository: vocabularyRepository,
      conversationRepository: conversationRepository,
      feedbackRepository: feedbackRepository,
      llmProvider: llmProvider,
      orchestrator: orchestrator,
      jwtService: JwtService(EnvConfig.instance),
      passwordHasher: const PasswordHasher(),
    );
  }
}
