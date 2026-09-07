# Project Structure

## Personal Portfolio & Publishing Platform

> The complete directory layout of all three repositories, what each folder is
> for, and which rules govern it.

See [SUBMODULES.md](SUBMODULES.md) for why the project is split this way.

---

# 1. Three Repositories

```text
ChamathDilshanC/chamathdilshan             main / umbrella  — never deployed
ChamathDilshanC/chamathdilshan.dev         frontend         — deployed on its own
ChamathDilshanC/api.chamathdilshan.dev     backend          — deployed on its own
```

---

# 2. Main Repository

```text
chamathdilshan/
│
├── chamathdilshan.dev/              → submodule (frontend)
├── api.chamathdilshan.dev/          → submodule (backend)
│
├── database/                        Schema source of truth
│   ├── migrations/                  Alembic / SQL migrations, version controlled
│   ├── schema/                      Current schema snapshot + ER notes
│   └── seed/                        Seed data for local development
│
├── docs/
│   ├── Architecture.md              System architecture, content model, API, auth
│   ├── TECH_STACK.md                Technology choices per layer
│   ├── SECURITY.md                  Threat model, authorization, hardening
│   ├── CACHING.md                   Cache layers, TTLs, invalidation
│   ├── SUBMODULES.md                Repository split and submodule workflow
│   └── PROJECT_STRUCTURE.md         This file
│
├── scripts/
│   ├── bootstrap.sh                 Clone submodules, install deps, seed .env
│   ├── update-submodules.sh         Pull + move submodules to pinned commits
│   └── verify-git.sh                Pre-push identity / secret / pointer check
│
├── .github/
│   ├── workflows/
│   │   ├── submodules.yml           Validate .gitmodules and pinned commits
│   │   ├── commit-policy.yml        Author identity + AI attribution check
│   │   └── secrets-scan.yml         Gitleaks + tracked-secret-file check
│   └── PULL_REQUEST_TEMPLATE.md
│
├── .githooks/
│   ├── commit-msg                   Blocks AI trailers, enforces <type>: format
│   └── pre-commit                   Blocks secrets and wrong Git identity
│
├── GITPUSH.md                       Local-only Git policy — listed in .gitignore
├── .env.example                     Master list of every variable in the system
├── .gitignore
├── .gitattributes
├── .gitmodules
├── .gitmessage                      Commit message template
├── README.md
└── LICENSE
```

## Rules for the main repo

```text
Never deployed. No application code.
database/ is the single source of truth for schema.
docs/ is the single source of truth for architecture decisions.
GITPUSH.md stays local — it is in .gitignore and is never published.
Submodule pointer bumps are their own commits.
```

---

# 3. Frontend — `chamathdilshan.dev`

```text
chamathdilshan.dev/
│
├── app/
│   ├── layout.tsx                   Root layout, metadata base, fonts
│   ├── page.tsx                     Home — static + ISR
│   ├── globals.css
│   ├── sitemap.ts
│   ├── robots.ts
│   │
│   ├── (public)/                    Public pages — force-static + ISR
│   │   ├── about/
│   │   ├── projects/
│   │   │   └── [slug]/
│   │   ├── blog/
│   │   │   └── [slug]/
│   │   ├── research/
│   │   │   └── [slug]/
│   │   ├── experience/
│   │   ├── education/
│   │   ├── certifications/
│   │   ├── achievements/
│   │   ├── skills/
│   │   ├── contact/
│   │   ├── resume/
│   │   └── search/
│   │
│   ├── ChamathDilshanC/             Admin UI — force-dynamic, no-store, noindex
│   │   ├── layout.tsx               Sets dynamic/fetchCache/robots for the subtree
│   │   ├── login/
│   │   ├── callback/
│   │   ├── dashboard/
│   │   ├── projects/
│   │   ├── blog/
│   │   ├── research/
│   │   ├── experience/
│   │   ├── education/
│   │   ├── certifications/
│   │   ├── achievements/
│   │   ├── skills/
│   │   ├── media/
│   │   ├── messages/
│   │   ├── audit-logs/
│   │   └── settings/
│   │
│   └── api/
│       └── revalidate/route.ts      Secret-protected on-demand cache invalidation
│
├── components/
│   ├── layout/                      Navbar, Footer, Container
│   ├── ui/                          Buttons, inputs, primitives
│   ├── cards/                       ProjectCard, BlogCard, ResearchCard, Timeline
│   ├── admin/                       Tables, editors, media manager
│   └── seo/                         Structured data, OG helpers
│
├── features/                        Feature-scoped composition
│   ├── projects/
│   ├── blog/
│   ├── research/
│   └── profile/
│
├── lib/
│   ├── api.ts                       The only server-side backend client
│   ├── cache-tags.ts                Tag vocabulary + TTL constants
│   ├── api-types.ts                 GENERATED from OpenAPI — gitignored
│   └── types/                       Hand-written domain types
│
├── hooks/                           Client hooks (SWR wrappers for admin)
├── public/                          Static assets served as-is
├── styles/
├── tests/
│
├── .github/workflows/ci.yml         Lint · typecheck · test · build
├── next.config.ts                   Images, security headers, admin no-store
├── tsconfig.json
├── package.json
├── .env.example
├── .gitignore
└── README.md
```

## Rules for the frontend

```text
Every server read goes through lib/api.ts — no bare fetch() to the backend.
Cache tags come from lib/cache-tags.ts and must match the backend's tags.
Public routes: force-static + revalidate. Admin routes: force-dynamic + no-store.
API types are generated (npm run gen:api), never hand-maintained.
Hiding an admin button is not security — the backend is the boundary.
```

---

# 4. Backend — `api.chamathdilshan.dev`

```text
api.chamathdilshan.dev/
│
├── app/
│   ├── main.py                      App entry, CORS, health, router registration
│   │
│   ├── api/
│   │   ├── public/                  Unauthenticated reads
│   │   │   ├── profile.py
│   │   │   ├── projects.py
│   │   │   ├── blog.py
│   │   │   ├── research.py
│   │   │   ├── taxonomy.py          skills / experience / education
│   │   │   ├── credentials.py       certifications / achievements
│   │   │   ├── search.py
│   │   │   └── contact.py           POST only, rate limited, no-store
│   │   │
│   │   ├── admin/                   Owner-only — every route authorized
│   │   │   ├── dashboard.py
│   │   │   ├── projects.py
│   │   │   ├── blog.py
│   │   │   ├── research.py
│   │   │   ├── media.py
│   │   │   ├── messages.py
│   │   │   ├── audit_logs.py
│   │   │   ├── settings.py
│   │   │   └── cache.py             Stats + manual purge (audit-logged)
│   │   │
│   │   ├── auth/
│   │   │   └── github.py            OAuth start, callback, session, logout
│   │   │
│   │   └── deps.py                  Shared dependencies (db, session, owner guard)
│   │
│   ├── core/
│   │   ├── config.py                Settings from environment
│   │   ├── cache.py                 Redis cache-aside, tags, frontend revalidate
│   │   ├── http_cache.py            Cache-Control / ETag policies
│   │   ├── security.py              Session signing, owner ID verification
│   │   └── logging.py
│   │
│   ├── models/                      SQLAlchemy ORM models
│   ├── schemas/                     Pydantic request/response models
│   ├── services/                    Business logic — owns post-commit invalidation
│   ├── repositories/                Database access, parameterized queries only
│   ├── integrations/                Supabase, GitHub, storage clients
│   └── security/                    Middleware, rate limiting, upload validation
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── .github/workflows/ci.yml         Lint · typecheck · test · build image
├── Dockerfile                       Non-root, healthcheck, multi-stage
├── pyproject.toml
├── .env.example
├── .gitignore
└── README.md
```

## Rules for the backend

```text
Every /api/admin/* route verifies the session and the GitHub owner ID server-side.
Every public GET applies an http_cache policy. Everything else is no-store.
Every mutation calls flush_content(tags, paths) AFTER the transaction commits.
Repositories use parameterized queries. Never string-built SQL.
Secrets only from the environment. Never logged, never in error responses.
```

---

# 5. Layer Boundaries

```text
Browser
   │  only talks to Next.js and the public API
   ▼
Next.js  (chamathdilshan.dev)
   │  presentation only — no business logic, no direct DB access
   ▼
FastAPI  (api.chamathdilshan.dev)
   │  all business logic, authorization, validation, caching
   ▼
Supabase PostgreSQL + Storage
      single source of truth
```

The browser never reaches the database. Next.js never reaches the database.

---

# 6. Where Things Belong

| Thing | Lives in | Why |
|---|---|---|
| Architecture decisions | main `docs/` | Applies to both apps |
| DB migrations | main `database/` | Owned by neither app |
| Environment master list | main `.env.example` | One place to see every variable |
| Git policy & hooks | main root | Governs all three repos |
| Page components | frontend `components/` | Presentation only |
| Cache tag names | both, mirrored | Frontend `lib/cache-tags.ts` ↔ backend service tags |
| Business rules | backend `services/` | Never in the frontend |
| Validation | backend `schemas/` | Frontend validation is UX only |
| API types | generated | From backend OpenAPI, never hand-written |
| Secrets | host environment | Never in any repo |

---

# 7. Naming Conventions

```text
Frontend files      PascalCase components (ProjectCard.tsx)
                    camelCase utilities   (formatDate.ts)
                    kebab-case routes     (audit-logs/)

Backend files       snake_case modules    (http_cache.py)
                    PascalCase classes    (BlogService)
                    snake_case functions  (get_published_by_slug)

Database            snake_case tables     (blog_posts, contact_messages)
                    plural table names
                    singular column names

Cache tags          lowercase, colon-scoped  (blog, post:<slug>, project:<slug>)
Branches            feature/* fix/* docs/* refactor/* security/*
Commits             <type>: <description>
```

---

# 8. Structure Checklist

```text
[ ] Main repo holds docs, database, scripts, CI, hooks — no app code
[ ] GITPUSH.md present locally and listed in .gitignore
[ ] Both app folders are real submodules with pushed remotes
[ ] .gitmodules declares path, url and branch for both
[ ] Each repo has its own .gitignore and .env.example
[ ] Each app repo has its own CI workflow
[ ] Frontend admin subtree is force-dynamic + no-store + noindex
[ ] Frontend has no direct database access
[ ] Backend has a router per resource, admin routers all authorized
[ ] Backend mutations all call flush_content after commit
[ ] core.hooksPath is set to .githooks
[ ] commit.template is set to .gitmessage
[ ] No .env file is tracked in any repo
```
