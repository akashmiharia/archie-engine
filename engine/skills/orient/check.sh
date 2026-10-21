#!/bin/bash
# /orient deterministic checks. Prints only DRIFT/WARN lines + one SUMMARY line.
# No output between here and SUMMARY = brain intact.
#
# Machine-specific paths come from ~/.claude/engine.conf (optional, shell syntax):
#   MEMDIR="…"          auto-memory dir (default: derived from $HOME, see below)
#   WORKSPACES="a b c"  space-separated dirs that must exist (default: none)
#   IDENTITY_FILE="…"   optional identity doc whose "Last updated:" stamp is reported
# Generic since 2026-10-20 (portable engine v0); before that these were hardcoded.
#
# Notes for future-Claude:
# - Memory checks use grep -F (fixed string). A regex char class here once silently
#   excluded digit-bearing filenames and produced false-positive UNINDEXED reports
#   (bug hit 2026-05-15). Do not "improve" back to regex.
# - log_latest reads only entry-header dates ("## [YYYY-MM-DD]" and "**YYYY-MM-DD"
#   line starts), NOT all dates in log.md — a body-text expiry date (2027-06-17)
#   produced a false staleness WARN on first run 2026-08-02.
# - The auto-memory project dir name is derived from the session's git root (or cwd
#   outside git) with "/" replaced by "-". That rule is observed on disk, not documented,
#   so a missing expected dir is a WARN with a glob fallback, never a DRIFT.

CD="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
K="${ARCHIE_KNOWLEDGE:-$CD/knowledge}"
CONF="$CD/engine.conf"
[ -f "$CONF" ] && . "$CONF"
: "${MEMDIR:=$CD/projects/$(echo "$HOME" | tr '/' '-')/memory}"
: "${WORKSPACES:=}"
: "${IDENTITY_FILE:=}"
MEM="$MEMDIR"

# --- 1. Load-bearing files & dirs ---
for p in "$K/index.md" "$K/SCHEMA.md" "$K/entities.json" "$K/SESSION.md" \
         "$K/wiki/source" "$K/wiki/concept" "$K/wiki/entity" "$K/wiki/idea" "$K/wiki/project" \
         $WORKSPACES $IDENTITY_FILE; do
  [ -e "$p" ] || echo "DRIFT missing load-bearing path: $p"
done

# --- 2. Wiki counts: disk vs index.md claims ---
total_disk=0
for t in source concept entity idea project; do
  n=$(ls "$K/wiki/$t/"*.md 2>/dev/null | wc -l | tr -d ' ')
  total_disk=$((total_disk + n))
  T="$(echo "$t" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
  claim=$(grep -m1 -E "^- $T: [0-9]+" "$K/index.md" | grep -oE '[0-9]+')
  if [ -n "$claim" ] && [ "$claim" != "$n" ]; then
    echo "DRIFT count $t: index.md claims $claim, disk has $n"
  fi
done
claim_total=$(grep -m1 -oE 'Total: [0-9]+' "$K/index.md" | grep -oE '[0-9]+')
if [ -n "$claim_total" ] && [ "$claim_total" != "$total_disk" ]; then
  echo "DRIFT count total: index.md claims $claim_total, disk has $total_disk"
fi

# --- 3. Per-page index coverage (catches what count-matching can miss) ---
for f in "$K"/wiki/*/*.md; do
  [ -e "$f" ] || continue
  rel="wiki/$(basename "$(dirname "$f")")/$(basename "$f")"
  grep -qF "($rel)" "$K/index.md" || echo "DRIFT unindexed wiki page: $rel"
done
grep -oE '\(wiki/[a-z]+/[A-Za-z0-9._-]+\.md\)' "$K/index.md" | tr -d '()' | sort -u | while read -r rel; do
  [ -f "$K/$rel" ] || echo "DRIFT orphan index.md link: $rel"
done

# --- 4. Memory index integrity ---
mem_n=0
if [ -d "$MEM" ]; then
  mem_n=$(ls "$MEM"/*.md 2>/dev/null | grep -cv 'MEMORY\.md$' | tr -d ' ')
  if [ -f "$MEM/MEMORY.md" ]; then
    for f in $(ls "$MEM"/*.md 2>/dev/null | grep -v 'MEMORY\.md$' | xargs -n1 basename); do
      grep -qF "$f" "$MEM/MEMORY.md" || echo "DRIFT unindexed memory: $f"
    done
    grep -oE '\(([A-Za-z0-9_.-]+\.md)\)' "$MEM/MEMORY.md" | tr -d '()' | sort -u | while read -r f; do
      [ -f "$MEM/$f" ] || echo "DRIFT orphan memory pointer: $f"
    done
  fi
  recent=$(find "$MEM" -name '*.md' -mtime -1 | wc -l | tr -d ' ')
  if [ "$recent" -gt 0 ]; then
    echo "WARN memory modified <24h (parallel session?): $(find "$MEM" -name '*.md' -mtime -1 -exec basename {} \; | tr '\n' ' ')"
  fi
else
  found=$(ls "$CD"/projects/*/memory/MEMORY.md 2>/dev/null | head -3 | tr '\n' ' ')
  [ -n "$found" ] && echo "WARN memory dir not at expected $MEM; found: $found (set MEMDIR in $CONF)"
fi

# --- 5. AGENTS.md line ceiling ---
agents_lines=$(wc -l < "$CD/AGENTS.md" 2>/dev/null | tr -d ' ')
[ "${agents_lines:-0}" -gt 150 ] && echo "WARN AGENTS.md over 150-line target: $agents_lines lines"

# --- 6. Freshness: SESSION.md stamp vs latest date in log.md ---
sess=$(grep -m1 -oE 'Last updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$K/SESSION.md" 2>/dev/null | grep -oE '[0-9-]+$')
logmax=$( { grep -oE '^## \[20[0-9]{2}-[0-9]{2}-[0-9]{2}\]' "$K/log.md"; grep -oE '^\*\*20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$K/log.md"; } 2>/dev/null | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
if [ -n "$sess" ] && [ -n "$logmax" ] && [[ "$logmax" > "$sess" ]]; then
  echo "WARN SESSION.md stamp ($sess) older than latest log.md date ($logmax) — semantic drift candidate"
fi

# --- SUMMARY (always last line) ---
skills=$(ls "$CD/skills" 2>/dev/null | wc -l | tr -d ' ')
ent=$(python3 -I -c "
import json, sys
d = json.load(open(sys.argv[1]))
if isinstance(d, dict):
    d = d.get('entities', d)
print(len(d))" "$K/entities.json" 2>/dev/null || echo '?')
summary="SUMMARY pages=$total_disk memories=$mem_n entities=$ent skills=$skills agents_lines=${agents_lines:-0} session_stamp=${sess:-none} log_latest=${logmax:-none}"
if [ -n "$IDENTITY_FILE" ] && [ -f "$IDENTITY_FILE" ]; then
  id_stamp=$(grep -m1 'Last updated:' "$IDENTITY_FILE" | grep -m1 -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  summary="$summary identity_md=${id_stamp:-?}"
fi
echo "$summary"
