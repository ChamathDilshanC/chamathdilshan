# Repository & Submodule Structure

## Personal Portfolio & Publishing Platform

> How this platform is split across Git repositories: one **main (umbrella) repo**
> plus a small number of **git submodules** for the parts that must be hosted
> and deployed independently.

Read together with [Architecture.md](Architecture.md), [TECH_STACK.md](TECH_STACK.md),
[CACHING.md](CACHING.md) and [GITPUSH.md](../GITPUSH.md).

---

# 1. Why Submodules

A single monorepo makes deployment awkward:

```text
Host wants:  repo root == app root
Monorepo:    repo root == apps/web + apps/api + database + docs + ...
Result:      backend host builds the whole tree, frontend host builds the whole
             tree, CI runs everything on every change, deploy configs fight the
             directory nesting.
```

Splitting the **deployable apps** into their own repositories fixes this:

- The backend host points at the backend repo root. Nothing else is in the way.
- The frontend host points at the frontend repo root. Nothing else is in the way.
- Each app has its own build, its own CI, its own deploy trigger, its own history.
- The main repo stays a light coordination layer: docs, DB schema, shared config.

## Rules

```text
Submodules ONLY for things that are deployed/hosted on their own.
Everything shared or non-deployable stays in the main repo.
Keep the submodule count minimal — 2 is the target, not 6.
```

---

# 2. Repository Topology

```text
ChamathDilshanC/chamathdilshan                (MAIN / umbrella repo)
│
├── chamathdilshan.dev/          → submodule → ChamathDilshanC/chamathdilshan.dev
│                                   Next.js 16 frontend (public site + admin UI)
│                                   hosted independently (repo root = app root)
│
├── api.chamathdilshan.dev/      → submodule → ChamathDilshanC/api.chamathdilshan.dev
│                                   FastAPI backend
│                                   hosted independently (repo root = app root)
│
├── database/                    (IN MAIN — not a submodule)
│   ├── migrations/
│   ├── schema/
│   └── seed/
│
├── docs/                        (IN MAIN)
│   ├── Architecture.md
│   ├── TECH_STACK.md
│   ├── SECURITY.md
│   ├── CACHING.md
│   ├── PROJECT_STRUCTURE.md
│   └── SUBMODULES.md   ← this file
│
├── GITPUSH.md                   (IN MAIN, but .gitignored — local policy only)
├── .github/workflows/           (IN MAIN — orchestration / cross-repo checks)
├── .githooks/                   (IN MAIN — commit-msg + pre-commit policy)
├── scripts/                     (IN MAIN — dev + ops tooling)
├── .env.example                 (IN MAIN — master variable list)
├── .gitmodules
├── .gitattributes
├── .gitignore
└── README.md
```

> Repo names above are the recommended defaults. `chamathdilshan.dev` is fixed by
> request (it is the domain). The main repo (`chamathdilshan`) and backend repo
> (`api.chamathdilshan.dev`) names can be changed — just keep them consistent
> everywhere.

---

# 3. What Lives Where

## 3.1 Main repo (`chamathdilshan`)

Holds everything that is **shared, coordinating, or not independently deployed**.

```text
database/         Single source of truth for the DB schema + migrations.
                  Both apps depend on this shape; it belongs to neither.

docs/             Architecture, security, caching, git policy, this document.

.github/          Cross-repo CI: submodule pointer checks, doc lint, link check,
                  "does the pinned frontend build against the pinned backend"
                  smoke checks if desired.

scripts/          bootstrap.sh, update-submodules.sh, db migrate helpers,
                  local dev orchestration (docker compose for full stack).

.env.example      The complete list of every variable used by any part of the
                  system (frontend + backend + caching + storage + OAuth).

.gitmodules       Submodule registry.

README.md         Entry point: clone instructions, how the pieces fit.
```

The main repo is **not deployed anywhere**. It is a workspace + record.

## 3.2 Frontend submodule (`chamathdilshan.dev`)

```text
Next.js 16 App Router, React, TypeScript, Tailwind.
Public website + /ChamathDilshanC admin UI.
Own package.json, own CI, own deploy.
Consumes the backend over HTTPS via NEXT_PUBLIC_API_URL.
Generates its API types from the backend OpenAPI spec (see §9).
```

## 3.3 Backend submodule (`api.chamathdilshan.dev`)

```text
FastAPI, Python, Pydantic, SQLAlchemy, Supabase client, Redis.
REST API + business logic + auth + authorization + caching + audit logging.
Own pyproject.toml / requirements, own Dockerfile, own CI, own deploy.
Runs the migrations from database/ (vendored or copied in at build — see §8).
```

---

# 4. Submodule Registry

| Path | Repository | Stack | Deployed as | Independent host |
|---|---|---|---|---|
| `chamathdilshan.dev/` | `ChamathDilshanC/chamathdilshan.dev` | Next.js 16 | `https://chamathdilshan.dev` | yes |
| `api.chamathdilshan.dev/` | `ChamathDilshanC/api.chamathdilshan.dev` | FastAPI | `https://api.chamathdilshan.dev` | yes |

Two submodules. Nothing else becomes a submodule unless it too needs its own
independent deployment.

---

# 5. `.gitmodules`

```ini
[submodule "chamathdilshan.dev"]
	path = chamathdilshan.dev
	url = https://github.com/ChamathDilshanC/chamathdilshan.dev.git
	branch = main

[submodule "api.chamathdilshan.dev"]
	path = api.chamathdilshan.dev
	url = https://github.com/ChamathDilshanC/api.chamathdilshan.dev.git
	branch = main
```

---

# 6. First-Time Setup

## 6.1 Clone the whole platform

```bash
git clone --recurse-submodules https://github.com/ChamathDilshanC/chamathdilshan.git
cd chamathdilshan
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

## 6.2 Promoting the scaffolded folders to real submodules

The working tree already contains the full structure, but `chamathdilshan.dev/`
and `api.chamathdilshan.dev/` are still **plain folders**, not submodules. They
become submodules once each has its own GitHub repository.

```text
1. Create the three GitHub repos (empty, no README):
     ChamathDilshanC/chamathdilshan            (main)
     ChamathDilshanC/chamathdilshan.dev        (frontend)
     ChamathDilshanC/api.chamathdilshan.dev    (backend)

2. Turn the frontend folder into its own repo and push it:
     cd chamathdilshan.dev
     git init -b main
     git remote add origin https://github.com/ChamathDilshanC/chamathdilshan.dev.git
     git add . && git commit -m "chore: scaffold Next.js frontend"
     git push -u origin main
     cd ..

3. Same for the backend:
     cd api.chamathdilshan.dev
     git init -b main
     git remote add origin https://github.com/ChamathDilshanC/api.chamathdilshan.dev.git
     git add . && git commit -m "chore: scaffold FastAPI backend"
     git push -u origin main
     cd ..

4. Register them as submodules in the main repo. The folders must be removed
   from the main working tree first — `git submodule add` refuses to overwrite
   an existing directory:
     rm -rf chamathdilshan.dev api.chamathdilshan.dev
     git submodule add https://github.com/ChamathDilshanC/chamathdilshan.dev.git chamathdilshan.dev
     git submodule add https://github.com/ChamathDilshanC/api.chamathdilshan.dev.git api.chamathdilshan.dev

5. Commit the pointers:
     git add .gitmodules chamathdilshan.dev api.chamathdilshan.dev
     git commit -m "chore: add frontend and backend submodules"
     git push -u origin main
```

> Step 4 deletes the local folders and re-clones them from GitHub. Only run it
> **after** step 2 and 3 have pushed successfully, or the scaffolding is lost.

---

# 7. Day-to-Day Workflow

## 7.1 The mental model

```text
A submodule is a pinned pointer to ONE commit of another repo.

main repo  ──points at──►  chamathdilshan.dev @ abc1234
main repo  ──points at──►  api.chamathdilshan.dev @ def5678

Changing app code   = commit inside the submodule + push
Updating the pointer = commit in main after the submodule moved
```

## 7.2 Making a change to the frontend

```bash
cd chamathdilshan.dev
git checkout -b feature/project-cards
# ... edit, build, test ...
git commit -m "feat: add project card grid"
git push origin feature/project-cards      # open PR in the frontend repo
# after merge:
git checkout main && git pull
```

Then record the new pointer in the main repo:

```bash
cd ..
git add chamathdilshan.dev
git commit -m "chore: bump frontend to project card grid"
git push
```

## 7.3 Pull latest everything

```bash
git pull
git submodule update --init --recursive     # move submodules to pinned commits
```

Or track branch tips instead of pinned commits:

```bash
git submodule update --remote --merge
```

## 7.4 Helper script (`scripts/update-submodules.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail
git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive
echo "Submodule state:"
git submodule status
```

---

# 8. Database Schema Sharing

`database/` lives in the **main repo** and is the single source of truth
(see [TECH_STACK.md](TECH_STACK.md) §8, §11).

The backend needs the migrations at build/run time. Pick one:

```text
Option A (recommended): the backend repo pulls database/ as its OWN submodule
        api.chamathdilshan.dev/
        └── database/   → submodule → ChamathDilshanC/chamathdilshan-db
        Requires splitting database/ into its own small repo.

Option B: CI copies database/ into the backend build context
        main CI publishes a versioned db bundle (tarball / package);
        backend CI downloads the pinned version before building.

Option C (simplest to start): database/ lives in the backend repo,
        main repo references it via the backend submodule.
        Downside: schema changes require a backend commit.
```

Start with **Option C**, move to **A** if a third consumer of the schema appears.

---

# 9. Shared API Contract (no submodule needed)

The frontend must not hand-maintain backend types.

```text
FastAPI  ──emits──►  /openapi.json
                         │
frontend CI  ──generates──►  chamathdilshan.dev/lib/api-types.ts
                         (openapi-typescript, run on every build)
```

```jsonc
// chamathdilshan.dev/package.json
"scripts": {
  "gen:api": "openapi-typescript $NEXT_PUBLIC_API_URL/openapi.json -o lib/api-types.ts"
}
```

This keeps types in sync without a `shared-types` submodule or package.

---

# 10. Environment Variables

```text
.env.example  (main repo)   → the COMPLETE master list, every variable, commented.

chamathdilshan.dev/.env.example       → only the frontend subset (NEXT_PUBLIC_*, etc.)
api.chamathdilshan.dev/.env.example   → only the backend subset (DB, OAuth secret,
                                        REDIS_URL, CACHE_REVALIDATE_SECRET, ...)
```

Real `.env` files are never committed in any repo (see [SECURITY.md](SECURITY.md) §11,
[GITPUSH.md](../GITPUSH.md) §14). Secrets are set in each host's environment.

---

# 11. CI/CD

```text
chamathdilshan.dev repo
   push → lint → typecheck → gen:api → test → build → deploy frontend host

api.chamathdilshan.dev repo
   push → lint → typecheck → test → build image → run migrations → deploy backend host

chamathdilshan (main) repo
   push → doc lint / link check
        → validate .gitmodules
        → (optional) full-stack smoke: bring up pinned frontend + pinned backend,
          hit /api/health and a couple of public pages
```

Each app deploys **on its own repo's push**, not on a main-repo push. The main
repo's CI only guarantees the pieces are coherent.

Follow [GITPUSH.md](../GITPUSH.md) for identity/attribution rules in **every** repo —
author and committer are `ChamathDilshanC` in the main repo and both submodules.

---

# 12. Deployment Mapping

```text
                         chamathdilshan.dev  (domain)
                                  │
                 ┌────────────────┴────────────────┐
                 ▼                                 ▼
   https://chamathdilshan.dev            https://api.chamathdilshan.dev
        Frontend host                         Backend host
   repo: chamathdilshan.dev            repo: api.chamathdilshan.dev
   root: repo root                     root: repo root
   build: next build                  build: docker / uvicorn
                                            │
                                  ┌─────────┴─────────┐
                                  ▼                   ▼
                          Supabase PostgreSQL   Supabase Storage
                                  ▲
                                  │
                            Redis (cache)
```

Neither host ever checks out the main repo. They only see their own submodule repo.

---

# 13. Pointer Discipline

```text
DO   commit the submodule pointer bump as its own small commit in main
DO   write which submodule and why:  "chore: bump backend to Redis cache-aside"
DO   run `git submodule update` after every `git pull` on main
DO   push the submodule BEFORE pushing the main-repo pointer that references it

DON'T commit a pointer to an unpushed submodule commit (breaks everyone's clone)
DON'T edit submodule files and forget to commit inside the submodule
DON'T let submodules drift onto detached-HEAD commits nobody tracks
DON'T turn shared docs or DB schema into submodules
```

Detect a broken pointer in CI:

```bash
git submodule foreach 'git cat-file -e HEAD || (echo "unpushed commit in $name" && exit 1)'
```

---

# 14. When To Add / Not Add a Submodule

```text
Add a submodule when a part:
  - is deployed to its own host, AND
  - wants its own build / release cadence / CI, AND
  - a hosting platform expects it at repo root

Keep it in the main repo when a part:
  - is documentation
  - is shared schema / config / types
  - is dev-only tooling
  - is only ever consumed, never deployed

Likely future submodule candidates (only if independently hosted):
  - a standalone worker / cron service
  - a separate marketing or docs site

Not submodule candidates:
  - shared TypeScript types  → generate from OpenAPI (§9)
  - UI component library     → npm package if it grows, otherwise stays in frontend
```

---

# 15. Checklist

```text
[ ] Main repo created: ChamathDilshanC/chamathdilshan
[ ] Frontend repo created: ChamathDilshanC/chamathdilshan.dev
[ ] Backend repo created: ChamathDilshanC/api.chamathdilshan.dev
[ ] Docs moved into main repo docs/
[ ] database/ location decided (Option A / B / C from §8)
[ ] .gitmodules committed with both submodules on branch = main
[ ] .env.example master list in main; per-app subsets in each submodule
[ ] scripts/update-submodules.sh + bootstrap in place
[ ] Frontend CI: gen:api from backend OpenAPI, build, deploy
[ ] Backend CI: test, build image, run migrations, deploy
[ ] Main CI: doc lint, .gitmodules validation, unpushed-pointer check
[ ] Deploy hosts point at submodule repo roots, not the main repo
[ ] Git identity = ChamathDilshanC in all three repos (GITPUSH.md)
[ ] README explains clone --recurse-submodules and the pointer workflow
```

---

# 16. Summary

```text
chamathdilshan            (main)   docs + DB schema + shared config + orchestration CI
├── chamathdilshan.dev    (sub)    Next.js frontend — hosted on its own
└── api.chamathdilshan.dev (sub)   FastAPI backend  — hosted on its own

Submodule count      : 2 (only the independently deployed apps)
Shared types         : generated from OpenAPI, not a submodule
Shared DB schema     : main repo, single source of truth
Main repo deploys    : nowhere — it is coordination + record
Each app deploys     : on its own repo's push, at its own repo root
```
