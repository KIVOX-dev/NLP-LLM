# Build phases

Tracks progress against the phase order from the master spec (§56). Update
this file as each phase lands.

## Done

- **Phase 1 — Project structure**: monorepo layout (`apps/`, `server/`,
  `packages/`, `dataset/`, `scripts/`, `docs/`, `docker/`).
- **Phase 2 — Flutter UI**: theme (light/dark), responsive chat screen
  (desktop sidebar / mobile drawer), reusable widgets (`AppSidebar`,
  `ChatMessage`→`ChatMessageBubble`, `SanskritInput`, `TranslationCard`,
  `WordAnalysisCard`, `GrammarCard`, `PronunciationCard`, `ConfidenceBadge`,
  `FeedbackButtons`, `LoadingIndicator`, `ErrorCard`). Not yet built:
  `DictionaryPopup`, `SettingsScreen`, `ConversationList` wired to real data,
  saved-translations UI.
- **Phase 3 — Dart Frog API**: all routes listed in spec §11 exist
  (`health`, `version`, `translate`, `chat`, `analyze`, `sandhi`,
  `pronunciation`, `dictionary/search`, `dictionary/:word`, `conversations`
  CRUD, `feedback`). Global middleware: request id, CORS, structured error
  envelope, optional-auth JWT, in-memory rate limiting.
- **Phase 4 — MongoDB**: connection singleton, collection name constants for
  every collection in spec §4, vocabulary + conversation + feedback
  repositories (interface + Mongo implementation).
- **Phase 5 — Translation endpoint**: `TranslationOrchestrator` implements
  the full 16-step pipeline from spec §12.
- **Phase 6 — LLM provider**: `LLMProvider` interface, `OpenAIProvider`
  implementation (JSON-mode chat completions, one controlled retry on
  invalid JSON), `ModelRouter` skeleton.
- **Phase 7 — Vocabulary repository**: done (see Phase 4).
- **Phase 8 — Word analysis**: dictionary-backed `SanskritMorphologyAnalyzer`
  + LLM merge in the orchestrator (grounded evidence wins; LLM only fills
  gaps).
- **Phase 9 — Conversation history**: repository + routes done; UI does not
  yet render saved history (no login flow to test it against).

## Partial / narrow-by-design (not gaps to "fix", just scope)

- **Sandhi**: rule-based analyzer only covers avagraha-triggered visarga
  sandhi (the spec's own worked example). Everything else is left to the
  LLM rather than guessed. Extending this into a general reverse-sandhi
  engine is real linguistic-engineering work, not a quick add.
- **Samāsa (compounds)**: `UnknownSamasaAnalyzer` always returns `unknown`.
  No rule-based classifier exists yet (spec §15 explicitly says not to force
  a classification).
- **Vedic accent**: modeled in `shared_models` (`AccentInfo`) but never
  populated — no accented-text data source is wired in, per spec §22.

## Not started

- **Phase 10 — Dataset generator**: `scripts/generate_dataset.dart`,
  `validate_dataset.dart`, `import_mongodb.dart`, `create_embeddings.dart`,
  and the 5,000-sentence dataset itself (spec §23–§28). This is a large,
  separate effort — do not start it casually inside an unrelated change.
- **Phase 11 — Evaluation**: held-out difficult test set (spec §28).
- **Vector search**: `NoOpVectorSearchService` is the only implementation.
  Needs `EMBEDDING_MODEL` + Atlas Vector Search index + an embedding
  provider call before `searchSimilarTranslations` etc. return anything.
- **Auth endpoints**: no `/auth/register`, `/auth/login`, `/auth/refresh`.
  `JwtService` and `PasswordHasher` exist and are unit-testable, but nothing
  issues a token over HTTP yet. Every auth-gated route currently 401s for
  real users.
- **Phase 13 — Testing**: unit tests exist for the pure-logic pieces
  (tokenizer/IAST/sandhi/pronunciation/validator, shared_models DTOs, the
  health route). Integration tests for `/translate`, `/chat`, dictionary
  search, conversation creation, and feedback are not written — they need
  either a live Mongo + OpenAI key or a mocked `AppServices`, which wasn't
  set up in this pass.
- **Phase 14 — Documentation**: `docs/API.md` and `docs/RUNNING.md` exist;
  no OpenAPI spec yet.
- **CI/CD**: no `.github/workflows/*` yet.
- **Internationalization**: UI strings are not yet externalized into ARB
  files / `flutter_localizations` — `AppConfig` centralizes the couple of
  strings that exist today, but this is not real i18n infrastructure.
- **Accessibility pass**: no explicit semantic labels/contrast/focus-order
  audit yet.
- Everything under spec §46 (voice input, OCR, flashcards, teacher/research
  mode, offline models, etc.) — intentionally deferred; extension points
  (e.g. `LocalTranslationProvider`, mic/upload buttons that are disabled
  placeholders) exist where the spec calls for them.
