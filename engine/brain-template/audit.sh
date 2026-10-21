#!/bin/bash
# Archie regression audit (engine template). Run after ANY structural change
# (sweep, scrub, bulk ingest, catalog rewrite). Deterministic, read-only,
# exits non-zero on failure. Companion to skills/orient/check.sh (session
# drift); this one is change-time.
set -u
KN="${ARCHIE_KNOWLEDGE:-$HOME/.claude/knowledge}"
FAIL=0
TMP="${TMPDIR:-/tmp}/archie-audit.$$"
mkdir -p "$TMP"
check() { # $1=name $2=result(0 ok) $3=evidence
  if [ "$2" -eq 0 ]; then echo "PASS $1 — $3"; else echo "FAIL $1 — $3"; FAIL=1; fi
}

# 1. Git integrity (only if the brain is a repo)
if git -C "$KN" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$KN" fsck --no-dangling >"$TMP/fsck" 2>&1
  check "git-fsck" $? "$(head -1 "$TMP/fsck" 2>/dev/null || echo clean)"
  DIRTY=$(git -C "$KN" status --short | wc -l | tr -d ' ')
  check "working-tree-committed" $([ "$DIRTY" -le 5 ]; echo $?) "$DIRTY uncommitted paths (<=5 tolerated mid-session)"
else
  echo "SKIP git checks — $KN is not a git repository (run: git -C \"$KN\" init)"
fi

# 2. Index counts vs disk
DISK=$(ls "$KN"/wiki/source/*.md "$KN"/wiki/concept/*.md "$KN"/wiki/entity/*.md "$KN"/wiki/idea/*.md "$KN"/wiki/project/*.md 2>/dev/null | wc -l | tr -d ' ')
CLAIM=$(grep -oE '\*\*Total: [0-9]+\*\*' "$KN/index.md" | grep -oE '[0-9]+')
check "index-counts" $([ "$DISK" = "${CLAIM:-x}" ]; echo $?) "disk=$DISK index=${CLAIM:-missing}"

# 3. Every wiki page is in the index, every index link resolves
UNINDEXED=0; ORPHAN=0
for f in "$KN"/wiki/*/*.md; do
  [ -e "$f" ] || continue
  rel="wiki/$(basename "$(dirname "$f")")/$(basename "$f")"
  grep -qF "($rel)" "$KN/index.md" || UNINDEXED=$((UNINDEXED+1))
done
for rel in $(grep -oE '\(wiki/[a-z]+/[A-Za-z0-9._-]+\.md\)' "$KN/index.md" | tr -d '()' | sort -u); do
  [ -f "$KN/$rel" ] || ORPHAN=$((ORPHAN+1))
done
check "index-coverage" $([ "$UNINDEXED" = 0 ] && [ "$ORPHAN" = 0 ]; echo $?) "unindexed=$UNINDEXED orphan-links=$ORPHAN"

# 4. entities.json parses + article paths exist
python3 -I - "$KN" <<'EOF' >"$TMP/ent" 2>&1
import json, os, sys
kn = sys.argv[1]
d = json.load(open(os.path.join(kn,'entities.json')))
ents = d.get('entities', d) if isinstance(d, dict) else d
missing = [e['canonical'] for e in ents if isinstance(e.get('article'), str) and not os.path.exists(os.path.join(kn, e['article']))]
print(f"{len(ents)} entities, {len(missing)} missing articles: {missing[:5]}")
sys.exit(1 if missing else 0)
EOF
check "entities-integrity" $? "$(cat "$TMP/ent")"

# 5. Frontmatter sanity: every wiki page opens with a frontmatter block that declares type
BADFM=0
for f in "$KN"/wiki/*/*.md; do
  [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' || BADFM=$((BADFM+1))
  grep -m1 -qE '^type: ' "$f" || BADFM=$((BADFM+1))
done
check "frontmatter" $([ "$BADFM" = 0 ]; echo $?) "$BADFM pages missing frontmatter or type"

# 6. No credential-shaped strings in the brain (keys never belong here)
HITS=$(grep -rEn '(sk-[A-Za-z0-9]{20,}|fc-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,})' "$KN/wiki" "$KN/raw" 2>/dev/null | wc -l | tr -d ' ')
check "no-credentials" $([ "$HITS" = 0 ]; echo $?) "$HITS credential-shaped strings"

rm -rf "$TMP"
echo
[ $FAIL -eq 0 ] && echo "AUDIT: ALL PASS" || echo "AUDIT: FAILURES PRESENT"
exit $FAIL
