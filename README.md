# Personal Portfolio & Publishing Platform

**Owner:** [ChamathDilshanC](https://github.com/ChamathDilshanC) · **Domain:** `chamathdilshan.dev`

Umbrella repository for a personal digital identity & publishing platform:
public portfolio, projects, blog, research/publications, media, and a private
owner-only administration panel.

This repo is **coordination only** — it is never deployed. The two deployable
applications live in their own repositories, wired in here as git submodules.

---

## Structure

```text
chamathdilshan/                     ← this repo (main / umbrella)
├── chamathdilshan.dev/             ← submodule · Next.js 16 frontend
├── api.chamathdilshan.dev/         ← submodule · FastAPI backend
├── database/                       ← schema, migrations, seed (source of truth)
├── docs/                           ← architecture, security, caching, structure
├── scripts/                        ← bootstrap, submodule + git verification
├── .github/workflows/              ← cross-repo CI (pointers, policy, secrets)
├── .githooks/                      ← commit-msg + pre-commit policy hooks
└── .env.example                    ← master variable list
```

Full tree and rationale: [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 16 (App Router), React, TypeScript, Tailwind CSS |
| Backend | FastAPI, Python, Pydantic, SQLAlchemy |
| Database | Supabase PostgreSQL |
| Storage | Supabase Storage |
| Cache | Redis + CDN + Next.js Data/Route cache |
| Auth | GitHub OAuth (owner-only) |
| CI/CD | GitHub Actions |

---

## Getting started

```bash
git clone --recurse-submodules https://github.com/ChamathDilshanC/chamathdilshan.git
cd chamathdilshan

git config core.hooksPath .githooks     # enable commit policy hooks
git config commit.template .gitmessage  # enable commit message template

./scripts/bootstrap.sh                  # install deps + seed .env files
```

Already cloned without submodules:

```bash
git submodule update --init --recursive
```

Run the apps:

```bash
cd chamathdilshan.dev      && npm run dev      # http://localhost:3000
cd api.chamathdilshan.dev  && uvicorn app.main:app --reload   # http://localhost:8000
```

---

## Working with submodules

Application code is committed **inside** the submodule. The main repo only
records which commit each submodule is pinned to.

```bash
# 1. change the app
cd chamathdilshan.dev
git checkout -b feature/project-cards
git commit -m "feat: add project card grid"
git push                                  # ← push the submodule FIRST

# 2. record the pointer
cd ..
git add chamathdilshan.dev
git commit -m "chore: bump frontend to project card grid"
git push
```

Pull everything:

```bash
./scripts/update-submodules.sh
```

Rules and failure modes: [docs/SUBMODULES.md](docs/SUBMODULES.md) §13

---

## Before pushing

```bash
./scripts/verify-git.sh
```

Checks identity, AI attribution, staged secrets, and submodule pointers.

---

## Documentation

| Document | Covers |
|---|---|
| [docs/Architecture.md](docs/Architecture.md) | System architecture, content model, API, auth flow |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Technology choices and responsibilities per layer |
| [docs/SECURITY.md](docs/SECURITY.md) | Threat model, authorization, secrets, hardening |
| [docs/CACHING.md](docs/CACHING.md) | Cache layers, TTLs, invalidation, failure handling |
| [docs/SUBMODULES.md](docs/SUBMODULES.md) | Repository split, submodule workflow, deployment mapping |
| [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) | Complete directory tree for every repo |

> The Git commit/push policy (`GITPUSH.md`) is kept local-only and is listed in
> `.gitignore`.

---

## Deployment

```text
https://chamathdilshan.dev        ← chamathdilshan.dev repo      (repo root = app root)
https://api.chamathdilshan.dev    ← api.chamathdilshan.dev repo  (repo root = app root)
```

Each application deploys on a push to **its own** repository. The main repo
never triggers a deployment.

---

## License

See [LICENSE](LICENSE).
