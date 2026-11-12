# GitHub AI Project Studio

GitHub AI Project Studio extends the existing owner-only Projects CMS. It does
not replace the project editor or expose GitHub/Gemini credentials to the
browser.

## Flow

```text
Discover → Analyze → Generate → Review → Design → Media → Draft / Publish
```

The browser calls the existing `/api/admin/*` boundary. The backend owns GitHub
access, bounded repository analysis, secret redaction, provider calls, validation,
draft persistence, and cache invalidation.

## Backend

- `GET /api/admin/github/repositories` lists, searches, sorts, paginates, and
  filters repositories. It marks repositories already linked to a project.
- `POST /api/admin/github/analyze` stores a durable analysis draft. The scan
  prioritizes README/configuration/architecture files and omits dependencies,
  generated files, binaries, sensitive files, and files beyond the configured
  budget.
- `GET /api/admin/studio/drafts/{id}` resumes a draft after refresh.
- `POST /api/admin/studio/drafts/{id}/generate` tries configured providers in
  `AI_PROVIDER_ORDER` (Gemini, Groq, then OpenRouter by default), validates every
  response with the canonical draft schema, and saves the winning provider/model.
- `PUT /api/admin/studio/drafts/{id}` saves reviewed content and design choices.
- `POST /api/admin/studio/projects` creates a normal CMS project, preserving the
  legacy fields plus the Studio template/content/repository data. Publishing is
  explicit and requires selected media.

Migration `0004_project_studio.py` adds `project_studio_drafts`,
`project_repositories`, and backward-compatible JSON columns on `projects`.
Migration `0005_ai_provider_metadata.py` adds provider and fallback-attempt
metadata to drafts.
Apply it separately before deploying the API:

```bash
alembic upgrade head
```

## Security and privacy

- `GITHUB_TOKEN`, `GEMINI_API_KEY`, `GROQ_API_KEY`, and `OPENROUTER_API_KEY` are
  backend-only variables.
- Public repository metadata can be discovered without a token.
- Private repositories default to metadata-only analysis. Explicit consent is
  required before evidence is sent to any configured AI provider.
- `.env`, key/certificate files, credential/token files, and secret-shaped
  values are omitted or redacted.
- The analyzer never executes repository code and sends only a compact,
  evidence-labelled summary to Gemini.
- AI drafts remain unpublished until the Admin chooses to publish them.
- Public pages only expose repository links copied into the project record.

## Templates

The public renderer keeps the existing `legacy` renderer for old projects and
supports five data-driven templates for Studio projects:

1. Minimal engineering case study
2. Editorial technical story
3. Product showcase
4. Architecture deep dive
5. Open source developer showcase

Template selection and media layout are independent fields. The same validated
project payload is rendered by the selected layout; switching templates does
not rewrite the underlying content or media references.

## Environment

Add the server-only variables from the backend `.env.example`:

```text
GITHUB_TOKEN=
GITHUB_ACCOUNT=ChamathDilshanC
GITHUB_MAX_FILES=120
GITHUB_MAX_BYTES=750000
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
GROQ_API_KEY=
GROQ_MODEL=openai/gpt-oss-120b
OPENROUTER_API_KEY=
OPENROUTER_MODEL=openrouter/free
AI_PROVIDER_ORDER=gemini,groq,openrouter
AI_FALLBACK_ENABLED=true
AI_PROVIDER_TIMEOUT_SECONDS=45
AI_TOTAL_TIMEOUT_SECONDS=180
```

OpenRouter is restricted to the configured model (`openrouter/free` by default);
the application rejects non-free OpenRouter model overrides and never silently
selects a paid model. Missing provider keys are
skipped, authentication failures stop the chain, and transient availability or
rate-limit failures may move to the next configured provider.

## Verification

Backend:

```bash
ruff check app migrations tests
pytest -q
```

Frontend:

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

Live provider calls require credentials and were not made during local
verification. The production health endpoint was reachable during this change;
an authenticated, controlled generation on a small public repository is still
required to verify the Vercel environment and actual provider access.
