#!/usr/bin/env bash
# Bootstrap the full platform for local development.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Fetching submodules"
git submodule sync --recursive
git submodule update --init --recursive

echo "==> Frontend (chamathdilshan.dev)"
if [ -f chamathdilshan.dev/package.json ]; then
  ( cd chamathdilshan.dev && npm install )
  [ -f chamathdilshan.dev/.env.local ] || cp chamathdilshan.dev/.env.example chamathdilshan.dev/.env.local
else
  echo "    package.json not found — scaffold Next.js first"
fi

echo "==> Backend (api.chamathdilshan.dev)"
if [ -f api.chamathdilshan.dev/pyproject.toml ]; then
  ( cd api.chamathdilshan.dev && python -m venv .venv && ./.venv/bin/pip install -e ".[dev]" )
  [ -f api.chamathdilshan.dev/.env ] || cp api.chamathdilshan.dev/.env.example api.chamathdilshan.dev/.env
else
  echo "    pyproject.toml not found — scaffold FastAPI first"
fi

echo
echo "==> Done. Fill in the .env files, then:"
echo "    cd chamathdilshan.dev      && npm run dev"
echo "    cd api.chamathdilshan.dev  && uvicorn app.main:app --reload"
