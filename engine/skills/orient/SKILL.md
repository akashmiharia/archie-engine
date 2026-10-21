---
name: orient
description: Use at session start, or when Akash says "orient me", "what's our state", "status check", "where are we", or asks any context-dependent question without a recent orientation in this session. Reads SESSION.md fully into context (never re-printed), runs deterministic disk checks via the skill's check.sh, and outputs a ~10-line exception-based brief — action items, active focus, brain status, drift only if found. Read-first: proposes fixes for approval, never auto-writes. Ends with the companions line (/notion-status, /archie-query, /archie-ingest, /session-ingest).
---

# Orient — Session-Start Brief + Drift Check

Session-start ritual for Akash's personal AI OS. **Disk-only, no network calls.** Two customers with two different contracts:

- **Claude** needs the full state loaded into context → read SESSION.md **completely and verbatim** (no selective pulling — that's the prompt-drift guarantee). Never re-print it: the moment it's read, it's in context; printing 170 lines serves no one.
- **Akash** needs "what was I doing, what's next" in ten seconds → a **brief, reported by exception**. All-clean is one line. Detail is earned by drift only.

**Read-first, never auto-write.** Detect, classify, offer. Fixes apply only on Akash's explicit go-ahead; Tier-1 files still trigger the protection hook normally.

**Auto-fire (2026-08-02):** a SessionStart hook (`~/.claude/hooks/session-orient.sh`, matchers `startup` + `clear` in `settings.json`) already runs check.sh and inlines SESSION.md into context at session start, instructing Claude to open its first reply with the brief. If that `<session-start-orient>` block is present and fresh in context, compose from it — skip steps 1-2. Manual `/orient` is for **mid-session re-orientation**, where state may have changed: run steps 1-2 fresh.

## Steps

### 1. Load state (silent)

Read `~/.claude/knowledge/SESSION.md` in full. This is context-loading, not output. Do not print or summarize it back unless Akash asks.

### 2. Run the deterministic checks

```bash
bash ~/.claude/skills/orient/check.sh
```

One script, ~2 seconds, covers everything: load-bearing files/dirs, wiki counts vs `index.md` claims, **per-page index coverage** (unindexed pages on disk, orphan links in the index — catches what count-matching can miss), memory index integrity, AGENTS.md line ceiling, SESSION.md-vs-log.md freshness. Output is only `DRIFT`/`WARN` lines plus a final `SUMMARY` line. Do not re-implement or "spot-check" these in prompt — the checks live in code so they can't drift. (The script's header comments record two past bugs — the `grep -F` memory-check regex trap and the log-date false positive — don't reintroduce them.)

### 3. Compose the brief

Target ~10 lines, hard ceiling ~20:

```
## Orient — [date]
[Brain status: "Brain intact. N pages, N memories, no drift." OR one line per DRIFT/WARN]

📌 Open: [SESSION.md action items, one line]
Active: [current focus + build queue, 1-2 lines]
Last session: [date + what it was] — [gap note if >1 week quiet]

/archie-query · /archie-ingest · /session-ingest · /archie-mine
```

Pull Open/Active from what you read in step 1. The companions line is mandatory — it's the discoverability mechanism for the Archie skill family.

### 4. Drift handling (only if check.sh flagged something)

Classify each flag:

- **Mechanical** (recomputable: count mismatch, unindexed page, orphan pointer) → one line each with the exact correction pre-computed, ending with a single **"say go"** offer. Apply only on approval.
- **Semantic** (only Akash knows the truth: stale SESSION.md, an uncaptured session) → one-line suggestion naming the right action. Name it precisely: a SESSION.md refresh is a SESSION.md refresh; `/session-ingest` captures sessions, it is not the SESSION.md editor.

If drift dominates (3+ items), lead the brief with drift and compress the rest.

## Hard rules

- ❌ Never print SESSION.md contents back. Read fully; output the brief.
- ❌ No auto-writes — fixes on explicit approval only.
- ❌ No network fetches and no skill chaining mid-orient.
- ❌ No skipping check.sh, no ad-hoc re-derivation of its checks in prompt.
- ✅ All-green = one line. Tables and sections only when something is wrong.
- ✅ Always end with the companions line.

## Why this shape (v2, 2026-08-02)

v1 printed SESSION.md verbatim plus all-green check tables: ~4-minute runs, unconsumable output. Root cause: the verbatim rule was an **ingestion** guarantee (don't let Claude lossy-summarize what it loads) misapplied to **presentation**. v2 splits the contracts — verbatim read, exception-based report — and moves the deterministic checks into `check.sh` per the deterministic-spine principle (deterministic ops = code; judgment = model). Latency was mostly output streaming, so the brief kills it.

Deep periodic sweeps (staleness, contradictions, link graphs, eval) belong to `/archie-audit` when it ships — orient stays the light, every-session baseline. Upstream prevention lives in `/session-ingest` (refreshes SESSION.md + counts at capture time), so orient should find near-zero drift in the normal flow.

## Companions

- `/archie-query <question>` — brain-first lookup of Archie
- `/archie-ingest <source>` — single-source ingest into Archie
- `/session-ingest` — capture the current session into Archie + memory + harness

Future companions (planned): `/archie-audit` (deep periodic sweep), `/archie-eval`, `/archie-corpus-mine`. Each joins this block as it ships.
