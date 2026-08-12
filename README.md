# SanskritAI Translator (working name)

A production-oriented Sanskrit → English + Tamil translation platform. It combines a
Sanskrit NLP pipeline (tokenization, IAST transliteration, sandhi, morphology, samāsa,
pronunciation) with dictionary/vector retrieval and an LLM, so translations are grounded
in linguistic evidence rather than relying solely on the model's internal knowledge.

The product name is a placeholder — see `apps/flutter_app/lib/core/config/app_config.dart`
and change one constant to rebrand.

## Status

This repository is being built in phases (see `docs/BUILD_PHASES.md`). What exists today:

- Monorepo structure (Phase 1)
- `shared_models` package: typed request/response DTOs shared by client and server
- Dart Frog backend: `/api/v1/health`, `/api/v1/version`, `/api/v1/translate`, plus
  stub routes for chat, dictionary, sandhi, analyze, pronunciation, conversations, feedback
- Sanskrit NLP pipeline: real tokenizer + Devanagari→IAST transliterator + syllabifier,
  rule-based sandhi splitter (vowel/visarga), dictionary-backed morphology lookup
- MongoDB repository interfaces + implementations (vocabulary, conversations)
- LLM provider abstraction with an OpenAI implementation; structured-JSON translation
  orchestrator with schema validation and an application-level confidence calculator
- Flutter app: ChatGPT-style chat screen wired to `POST /api/v1/translate`, dark/light
  theme, responsive sidebar-vs-drawer layout

Not yet built (see `docs/BUILD_PHASES.md` for the plan): authentication endpoints, samāsa
classifier, vector search backend, dataset generator/scripts, CI, Docker, full test suite.

## Repository layout

```
apps/flutter_app        Flutter client (Android, iOS, Web, Windows, macOS, Linux)
server/dart_frog_api     Dart Frog backend (REST API, orchestration, persistence)
packages/shared_models   DTOs shared between client and server
packages/api_client      Typed HTTP client used by the Flutter app (thin wrapper over Dio)
packages/sanskrit_core   Placeholder for pipeline logic extracted for reuse/offline mode
dataset/                 JSONL data: translation/{train,validation,test}, vocabulary/, morphology/, sandhi/, evaluation/
scripts/                 Dataset generation/validation/import tooling (Phase 10+)
docs/                    API docs, run instructions, architecture notes
docker/                  Dockerfile + docker-compose for local dev
```

## Requirements

- Flutter SDK (stable channel) — includes Dart
- Dart Frog CLI: `dart pub global activate dart_frog_cli`
- MongoDB Atlas cluster (or local MongoDB for dev)
- An OpenAI API key (or another provider once implemented)

None of these are installed in the environment this repo was scaffolded in — see
`docs/RUNNING.md` for exact setup and verification steps once you have the SDKs.

## Quick start

See [`docs/RUNNING.md`](docs/RUNNING.md).

## Security

- The Flutter app never talks to MongoDB or the LLM directly — only to the Dart Frog API.
- No secrets are committed. `.env.example` documents every required variable as a
  placeholder; copy it to `server/dart_frog_api/.env` and fill in real values locally.
