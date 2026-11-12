# GitHub AI Project Studio

GitHub AI Project Studio extends the existing owner-only Projects CMS. It does
not replace the project editor or expose GitHub/Gemini credentials to the
browser.

## Flow

```text
Discover → Analyze → Generate → Review → Design → Media → Draft / Publish
```

The browser calls the existing `/api/admin/*` boundary. The backend owns GitHub
access, bounded repository analysis, secret redaction, Gemini calls, validation,
draft persistence, and cache invalidation.

## Backend

- `GET /api/admin/github/repositories` lists, searches, sorts, paginates, and
  filters repositories. It marks repositories already linked to a project.
- `POST /api/admin/github/analyze` stores a durable analysis draft. The scan
  prioritizes README/configuration/architecture files and omits dependencies,
  generated files, binaries, sensitive files, and files beyond the configured
  budget.
- `GET /api/admin/studio/drafts/{id}` resumes a draft after refresh.
- `POST /api/admin/studio/drafts/{id}/generate` calls the configured Gemini
  model and validates the response with `StudioContent` before saving it.
- `PUT /api/admin/studio/drafts/{id}` saves reviewed content and design choices.
- `POST /api/admin/studio/projects` creates a normal CMS project, preserving the
  legacy fields plus the Studio template/content/repository data. Publishing is
  explicit and requires selected media.

Migration `0004_project_studio.py` adds `project_studio_drafts`,
`project_repositories`, and backward-compatible JSON columns on `projects`.
Apply it separately before deploying the API:

```bash
alembic upgrade head
```

## Security and privacy

- `GITHUB_TOKEN` and `GEMINI_API_KEY` are backend-only variables.
- Public repository metadata can be discovered without a token.
- Private repositories default to metadata-only analysis. Explicit consent is
  required before Gemini generation.
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
```

The selected model is configurable and generation fails clearly when Gemini is
not configured. No automatic paid-tier fallback is implemented.

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

Live GitHub/Gemini calls require credentials and were not made during local
verification. The test suite uses deterministic fixtures and pure safety
checks; production credentials, GitHub rate limits, Cloudinary uploads, and
Vercel runtime behavior still require deployment-environment verification.
