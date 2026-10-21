# Claude Code Addendum

> Claude Code-specific behaviors layered on top of `~/.claude/AGENTS.md` (the persona), which is imported below. Codex and Cursor read AGENTS.md directly and never see this file.

@~/.claude/AGENTS.md

---

## Session Start

The SessionStart hook (`hooks/session-orient.sh`) runs the orient checks and inlines `~/.claude/knowledge/SESSION.md` into context automatically. If that block is present, open your first reply with the orient brief and continue. If it is absent (hooks disabled by policy), run `/orient` yourself.

After that, read on demand only:

1. `~/.claude/knowledge/index.md` — the map of what the brain holds. Read it when a question could be answered from the brain.
2. Individual wiki pages — fetch when a task makes one relevant. Never bulk-load.

## Skills

Personal skills live in `~/.claude/skills/`. The harness loads each skill's description at session start. The Archie family: `/orient`, `/archie-query`, `/archie-ingest`, `/archie-mine`, `/session-ingest`, `/living-doc`.

Workspace skills (for example the PM kit) activate when you `cd` into that workspace.

## Memory

Auto-memory is on. Save observations about how the user works, not facts the brain already records. Memory files are Tier 1: confirm before writing.
