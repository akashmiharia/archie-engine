#!/bin/bash
# Leak gate: refuse a bundle that carries personal content or credentials.
# Usage: leak-gate.sh <dir> [--names <file>] [--strict]
#   --names FILE   one private person name per line (case-insensitive) that must not appear
#   --strict       exit 1 on any hit (default: report and exit 1 only on credential hits)
# Allowed files (public-by-design): README.md, TOMORROW.md, about.md, MANIFEST.md,
# and pages whose name starts with ebay-evo-design or session-ebay-live-case-study.
set -u
DIR="${1:?dir}"; shift
NAMES=""; STRICT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --names) NAMES="$2"; shift 2;;
    --strict) STRICT=1; shift;;
    *) echo "unknown arg $1"; exit 2;;
  esac
done
ALLOW='/(README\.md|TOMORROW\.md|about\.md|MANIFEST\.md|ebay-evo-design[^/:]*\.md|session-ebay-live-case-study[^/:]*\.md):'

PERSONAL='\bemma\b|\bwedding\b|engagement news|fianc|immigration|green card|\bh-?1b\b|\bi-?797\b|/Users/akash|-Users-akash|akashmiharia|\bmillie\b|petal practice'
CREDS='sk-[A-Za-z0-9]{20,}|fc-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{16,}'

fail=0
echo "== leak gate on $DIR =="
p_hits=$(grep -rniE "$PERSONAL" "$DIR" --exclude-dir=.git --exclude=leak-gate.sh 2>/dev/null | grep -vE "^[^:]*$ALLOW" || true)
if [ -n "$p_hits" ]; then
  echo "PERSONAL-CONTENT HITS:"; echo "$p_hits" | cut -c1-200
  [ $STRICT -eq 1 ] && fail=1
else
  echo "personal-content: clean"
fi
c_hits=$(grep -rnE "$CREDS" "$DIR" --exclude-dir=.git --exclude=leak-gate.sh 2>/dev/null || true)
if [ -n "$c_hits" ]; then
  echo "CREDENTIAL-SHAPED HITS:"; echo "$c_hits" | cut -c1-200; fail=1
else
  echo "credentials: clean"
fi
if [ -n "$NAMES" ] && [ -f "$NAMES" ]; then
  n_hits=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    h=$(grep -rniwF -- "$name" "$DIR" --exclude-dir=.git --exclude=leak-gate.sh 2>/dev/null | grep -vE "^[^:]*$ALLOW" || true)
    [ -n "$h" ] && n_hits="$n_hits
$h"
  done < "$NAMES"
  if [ -n "$(echo "$n_hits" | tr -d '\n')" ]; then
    echo "PRIVATE-NAME HITS:"; echo "$n_hits" | sed '/^$/d' | cut -c1-200
    [ $STRICT -eq 1 ] && fail=1
  else
    echo "private names: clean"
  fi
fi
for bad in settings.json settings.local.json .credentials.json history.jsonl; do
  if find "$DIR" -name "$bad" | grep -q .; then echo "FORBIDDEN FILE PRESENT: $bad"; fail=1; fi
done
if find "$DIR" -type d -name projects -path "*/.claude/*" | grep -q .; then echo "FORBIDDEN DIR PRESENT: projects/"; fail=1; fi
[ $fail -eq 0 ] && echo "LEAK GATE: PASS" || echo "LEAK GATE: FAIL"
exit $fail
