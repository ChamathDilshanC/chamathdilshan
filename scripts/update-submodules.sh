#!/usr/bin/env bash
# Pull the main repo and move submodules to their pinned commits.
set -euo pipefail
cd "$(dirname "$0")/.."

git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive

echo
echo "=== Submodule state ==="
git submodule status

echo
echo "=== Unpushed submodule commits (would break other clones) ==="
git submodule foreach --quiet '
  if ! git branch -r --contains HEAD | grep -q .; then
    echo "  !! $name is on a commit that is not on any remote branch"
  fi
' || true
echo "  (nothing listed above = all pointers are safe to push)"
