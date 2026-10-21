#!/bin/bash
# SessionStart hook — auto-orient (built 2026-08-02).
# Runs the /orient v2 deterministic checks and inlines SESSION.md so every new
# session starts oriented with zero prompting and zero tool calls.
# stdout is injected into Claude's context by the harness.
# Companion: ~/.claude/skills/orient/ (check.sh + SKILL.md own the logic; this
# script only delivers their output at session start).

# SessionStart passes JSON on stdin; `source` is startup|resume|clear|compact|fork.
# Added 2026-10-08: the `compact` matcher re-fires this hook after auto-compaction so the
# cockpit survives a compaction (silent-failure fix); the closing instruction adapts below.
SRC=$(python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("source",""))
except Exception: print("")' 2>/dev/null)

echo "<session-start-orient>"
echo "Auto-orient (SessionStart hook). Drift status from ~/.claude/skills/orient/check.sh — only DRIFT/WARN lines + SUMMARY appear:"
echo ""
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/orient/check.sh" 2>&1
echo ""
S="${ARCHIE_KNOWLEDGE:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/knowledge}/SESSION.md"
# Harness caps SessionStart stdout at 10k chars (overflow gets spilled to a file
# with only a preview). Guard: if SESSION.md re-bloats past ~7.5k, point instead
# of inlining — and surface the bloat itself as drift (cockpit must stay lean).
if [ "$(wc -c < "$S" | tr -d ' ')" -gt 7500 ]; then
  echo "WARN SESSION.md is $(wc -c < "$S" | tr -d ' ') chars — too large to inline under the hook's 10k stdout cap. Read $S from disk for the brief, and flag to the user that the cockpit has re-bloated (restructured lean 2026-08-02; archive overflow to log.md)."
else
  echo "--- SESSION.md (full, current — do not re-read from disk) ---"
  cat "$S"
  echo "--- end SESSION.md ---"
fi
echo ""
if [ "$SRC" = "compact" ]; then
  echo "Instruction to Claude: the context was just compacted. The cockpit above is current and is the plan registry — treat it as authoritative over anything the compaction summary says about next steps or open items. Say in one line that context was compacted and you re-oriented, then continue the task in progress. Do not re-run check.sh or re-read SESSION.md; both are current above."
else
echo "Instruction to Claude: open your FIRST reply with the /orient v2 brief (<=10 lines: brain status from the check output above; 📌 Open action items; Active focus + build queue; last-session gap; the companions line '/archie-query · /archie-ingest · /session-ingest · /archie-mine'), then address the user's message. If DRIFT/WARN lines appear above, classify mechanical vs semantic per the orient skill and offer fixes ('say go') — never auto-write. Do not re-run check.sh or re-read SESSION.md; both are current above. If the user's first message is /orient itself, just produce the brief from this data instead of re-running the skill's reads."
fi
echo "</session-start-orient>"
