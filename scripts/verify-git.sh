#!/usr/bin/env bash
# Pre-push verification — see GITPUSH.md §21, §22, §27
set -uo pipefail

EXPECTED_NAME="ChamathDilshanC"
fail=0

echo "=== Git Identity ==="
name="$(git config user.name  || true)"
mail="$(git config user.email || true)"
echo "  user.name  = ${name:-<unset>}"
echo "  user.email = ${mail:-<unset>}"
[ "$name" = "$EXPECTED_NAME" ] || { echo "  !! expected user.name = $EXPECTED_NAME"; fail=1; }
[ -n "$mail" ] || { echo "  !! user.email is not configured"; fail=1; }

echo
echo "=== Latest Commit ==="
git log -1 --format="  Author:    %an <%ae>"
git log -1 --format="  Committer: %cn <%ce>"

echo
echo "=== AI Attribution Check ==="
if git log -1 --format="%B%an%cn" | grep -Eiq 'claude|anthropic|copilot|co-authored-by|generated with'; then
  echo "  !! AI attribution found in the latest commit — fix before pushing"
  fail=1
else
  echo "  clean"
fi

echo
echo "=== Staged Secret Check ==="
SECRET_RE='(^|/)\.env($|\.)|\.pem$|\.key$|\.p12$|\.pfx$|credentials.*\.json$|service-account.*\.json$'
ALLOW_RE='\.(example|sample|template)$'
secrets="$(git diff --cached --name-only | grep -E "$SECRET_RE" | grep -Ev "$ALLOW_RE" || true)"
if [ -n "$secrets" ]; then
  echo "  !! a secret-looking file is staged"
  echo "$secrets"
  fail=1
else
  echo "  clean"
fi

echo
echo "=== Submodule Pointers ==="
git submodule status || true

echo
echo "=== Remote ==="
git remote -v

echo
echo "=== Status ==="
git status --short

echo
if [ "$fail" -eq 0 ]; then
  echo "OK — safe to push."
else
  echo "BLOCKED — resolve the items marked !! before pushing."
fi
exit "$fail"
