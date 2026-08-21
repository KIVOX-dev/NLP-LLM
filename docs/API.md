# API Reference (v1)

Base path: `/api/v1`. All responses are JSON. Errors always use the envelope:

```json
{ "error": { "code": "VALIDATION_FAILED", "message": "...", "request_id": "..." } }
```

Error codes: `VALIDATION_FAILED` (400), `UNAUTHORIZED` (401), `FORBIDDEN` (403),
`NOT_FOUND` (404), `RATE_LIMITED` (429), `TRANSLATION_FAILED` (502),
`UPSTREAM_UNAVAILABLE` (503), `INTERNAL_ERROR` (500).

Authentication: send `Authorization: Bearer <jwt>`. Most read/translate
endpoints work anonymously; conversation history requires auth. **No
registration/login endpoint exists yet** (see docs/BUILD_PHASES.md) — the
JWT verification path is implemented and testable once you mint tokens some
other way (e.g. a short script calling `JwtService.issueAccessToken`
directly) while the HTTP endpoints for signup/login are built.

---

## GET /health

No auth. Liveness check.

**200**
```json
{ "status": "ok", "timestamp": "2026-08-12T10:00:00.000Z" }
```

## GET /version

No auth.

**200**
```json
{ "api_version": "v1", "app_version": "0.1.0" }
```

---

## POST /translate

No auth required (attach `conversation_id` to persist — requires the
conversation to already exist and, today, requires no ownership check since
auth issuance isn't built yet; this will tighten once login exists).

**Request**
```json
{
  "text": "रामः वनं गच्छति।",
  "source_language": "sa",
  "targets": ["en", "ta"],
  "include_word_analysis": true,
  "include_grammar": true,
  "include_pronunciation": true,
  "include_sandhi": true,
  "include_compounds": true,
  "conversation_id": null
}
```
Only `text` is required; every other field defaults as shown. `text` max
length is `MAX_INPUT_CHARACTERS` (default 2000).

**Sentence formation**: if `text` is a single bare word (e.g. `गजः`) rather
than a sentence, the orchestrator first composes one short grounded Sanskrit
sentence containing that word, then runs the normal pipeline below on the
generated sentence — so a one-word query still returns a full translation,
word analysis, grammar, and pronunciation instead of a bare literal gloss.
`source.original` reflects the generated sentence, not the original single
word. This applies to `/chat` and `/analyze` too, since both wrap this same
orchestrator. See `TranslationOrchestrator._isSingleWord` /
`_formSentenceFor`.

**200**
```json
{
  "request_id": "…",
  "source": { "language": "sa", "original": "रामः वनं गच्छति।", "iast": "rāmaḥ vanaṃ gacchati." },
  "translations": { "en": "Rama goes to the forest.", "ta": "ராமன் காட்டிற்குச் செல்கிறான்." },
  "literal_translation": { "en": "...", "ta": "..." },
  "words": [ { "surface": "रामः", "iast": "rāmaḥ", "english_meaning": "...", "morphology": { "part_of_speech": "proper_noun", "confidence": "medium" } } ],
  "grammar": { "subject": "रामः", "verb": "गच्छति", "tense": "present" },
  "sandhi": [],
  "compounds": [],
  "pronunciation": { "original": "...", "iast": "...", "syllables": ["rā", "maḥ"], "guide": "rā-maḥ" },
  "confidence": { "level": "medium", "notes": [] },
  "uncertainties": [],
  "metadata": { "model_version": "gpt-4o-mini" }
}
```

**Errors**: `400 VALIDATION_FAILED` (empty/too-long text, unsupported
language), `502 TRANSLATION_FAILED` (LLM output failed schema validation
after one retry), `503 UPSTREAM_UNAVAILABLE` (LLM provider unreachable or
`OPENAI_API_KEY` unset).

---

## POST /chat

Same request/response shape as `/translate`, wrapped with:
```json
{ "conversation_id": "…or null if anonymous", "translation": { /* TranslationResponse */ } }
```
If the caller is authenticated and no `conversation_id` is given, a new
conversation is created automatically and both turns (user + assistant) are
persisted. Anonymous callers get a translation with no persistence.

---

## POST /analyze

Linguistic analysis only, no translation prose. Request: `{ "text": "...", "include_sandhi": true, "include_compounds": true, "include_pronunciation": true }`.
Response is a `TranslationResponse` with the `translations`/`literal_translation` fields dropped.

## POST /sandhi

Deterministic, rule-based only — **no LLM call**. Request: `{ "text": "रामोऽस्ति" }`.
```json
{ "source": "रामोऽस्ति", "sandhi": [{ "surface": "रामोऽस्ति", "components": ["रामः", "अस्ति"], "type": "visarga", "is_ambiguous": false }] }
```
Coverage is intentionally narrow (currently: avagraha-triggered visarga
sandhi only) — see `lib/src/nlp/sandhi_analyzer.dart`.

## POST /pronunciation

Deterministic, no LLM call. Request: `{ "text": "गच्छति" }` → a `PronunciationResult` JSON object.

---

## POST /dictionary/search

Request: `{ "query": "dharma", "limit": 20 }` → `{ "results": [VocabularyEntry, ...] }`.

## GET /dictionary/:word

URL-encode `:word` (lemma or IAST). 404 if not found.

---

## GET /conversations — auth required

`{ "conversations": [Conversation, ...] }`, newest-updated first.

## POST /conversations — auth required

Request: `{ "title": "..." }` → `201` + `Conversation`.

## GET /conversations/:id — auth required, must own it

`{ "conversation": Conversation, "messages": [ConversationMessage, ...] }`.

## DELETE /conversations/:id — auth required, must own it

`204` on success.

---

## POST /feedback

No auth required. Either a rating or a full correction:
```json
{ "translation_id": "…", "rating": "up" }
```
or
```json
{ "translation_id": "…", "language": "en", "original": "...", "incorrect_translation": "...", "correct_translation": "...", "comment": "..." }
```
`201` → `{ "id": "…" }`.
