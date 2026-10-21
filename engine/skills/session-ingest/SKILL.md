---
name: session-ingest
description: Use when Akash wants to ingest the current Claude Code session into Archie — typically when a chat has produced substantive work (design decisions, builds, shipped artifacts, brainstorms with real output) and the learnings shouldn't evaporate. Triggers on phrases like "ingest this session", "session-ingest this", "archive this session", "capture this chat", "let's wrap up this chat", "this conversation is worth keeping". User-triggered — most chats don't earn an archive; deep sessions do. Akash decides which sessions warrant capture; this skill mechanizes the extraction. Derives four artifact categories from the session — (1) wiki content (delegated to /archie-ingest for the canonical write), (2) memory candidates (Claude-side behavioral feedback, Akash identity facts, project state), (3) harness candidates (skill changes, hook configs, AGENTS.md edits), (4) output→wiki promotions. Surfaces all four for approval before any writes. Supports incremental ingest — captures only the delta when a prior /archie-ingest or /session-ingest already ran on this session. Never silently writes to memory or the harness; always surfaces, always approves.
---

# Session Ingest — chat → wiki, memory, and harness

User-triggered session capture. Sibling to [[skill-archie-ingest]] (which handles single external sources). This skill orchestrates the session-specific concerns then **delegates the wiki write portion to `/archie-ingest`** so the canonical 12-step SCHEMA flow isn't reinvented.

**Why this is a separate skill from `/archie-ingest`.** Per the first-principles separation locked 2026-05-20: `/archie-ingest` is the universal write-side primitive for ANY source (article, transcript, deck, paste-through). Sessions have three concerns external artifacts never have:

1. **Session-boundary judgment.** Most chats don't earn an archive. Deep design / build / brainstorm / strategy sessions do. The decision is user-triggered; the skill doesn't auto-fire.
2. **Memory routing.** Sessions produce Claude-behavior feedback (*"validate before execute"*, *"separation of concerns over Swiss Army knives"*) and Akash-identity facts (*"uses first-principles framing"*) that belong in `the auto-memory dir (`~/.claude/projects/<project>/memory/`)`, not the wiki.
3. **Harness improvements.** Sessions produce skill changes, hook configurations, AGENTS.md / CLAUDE.md edits. These touch the harness, not the wiki.

External-artifact ingestion never touches the last two; sessions touch them constantly. Composition over conflation.

## Hard rules — anti-patterns to never violate

- **No silent ingestion.** Even when Akash says *"ingest this session"*, surface the four artifact categories first. Discuss-before-compile checkpoint is mandatory.
- **No unilateral memory writes.** Memory candidates surface for approval. Akash writes them himself or the auto-memory system handles it; the skill never writes to `the auto-memory dir (`~/.claude/projects/<project>/memory/`)` directly.
- **No unilateral harness changes.** Skill / hook / AGENTS.md edits are blast-radius actions. Surface proposed Edits with full diff. Get explicit per-file approval before writing.
- **No conflating session source with build artifacts.** When a session built something (a skill, a project, a document), both the session source page (the design conversation) AND the project page (the shipped thing) belong in the wiki. Don't collapse them.
- **No reinventing the wiki write.** The wiki portion delegates to `/archie-ingest`. Same 12-step SCHEMA flow, same incremental-update discipline, same canonicalization routing, **same extract-before-synthesize enforcement for non-text sources**. Don't duplicate.
- **No timestamp-bump archives.** If a "session" was just Q&A with no real artifacts, don't force an archive. Tell Akash this one didn't earn it; offer to capture one or two specific learnings as memory candidates instead.

## Decision points — when to ask, when to proceed

| Situation | Action |
|---|---|
| User invokes mid-conversation | Treat as "capture-so-far"; identify any prior `/archie-ingest` or `/session-ingest` runs on this session and capture only the delta |
| User invokes at end of chat | Treat as full-session capture |
| Prior ingest exists; this is incremental | Surface boundary explicitly: "Previous ingest captured X. New content since: Y. Proceeding with delta." |
| Session produced a built artifact (skill, hook, project, HTML page) | Both pages: session source captures design conversation; project page captures the shipped thing. |
| Memory candidate identified | Surface; Akash approves; he or auto-memory writes. Never silent write. |
| Harness change identified | Surface proposed Edits with full context. Per-file approval. |
| Session is shallow (Q&A, single answer, no real work) | Tell Akash this likely doesn't earn a full archive; offer to capture 1-2 specific learnings as targeted memory candidates instead |
| Output worth promoting to wiki (briefing, synthesis, query answer used multiple times) | Surface as promotion candidate per Aakash Gupta's output→wiki pattern |
| Session touches sensitive content (family, partner, work-confidential) | Pause and flag privacy implications before any writes |

## The flow

### 1. Detect scope

- **Type:** end-of-chat full archive, or mid-conversation capture-so-far, or incremental delta from previous ingest?
- **Boundary (use the anchor, don't guess the slug):** every session-ingest stamps a **deterministic session marker** — `session-id: <YYYY-MM-DD-NN>` written into the session source page's Timeline AND the `log.md` line (see step 4). On an incremental run, find the prior capture by **matching that exact marker**, not by guessing a slug or scanning for fuzzy matches (the old, fragile method). If no marker exists, this is a first capture: mint a new session-id. If one exists, the delta is everything in the conversation after the marker's timestamp.
- **Earned:** is this a real session worth full ingestion, or a shallow chat that should get targeted-learning capture instead?

### 2. Extract the insights — then derive the four artifact categories

**First, the insight pass (do this before routing).** Routing without extraction is motions without capture — it's the reason a session-ingest can "run" and still miss what actually mattered. Before touching the four categories, scan the whole session (the delta, if incremental) and write down, in plain language:

- **Decisions made** — what did we settle, and why (the reasoning, not just the conclusion)?
- **What changed in understanding** — what do we now believe that we didn't at the start?
- **Corrections Akash gave** — where did he push back, redirect, or reframe? (These are the highest-signal feedback-memory candidates.)
- **What got built / shipped** — skills, pages, docs, code, artifacts.

This is the Reflexion pattern: extract the lesson from the session, don't just file the transcript. The four categories below are *routing destinations* for these extracted insights — so extract first, then route.

**Then derive the four artifact categories.** For each, enumerate candidates explicitly before writing. Skip categories that don't apply to this session.

**A. Memory candidates.** Route to `the auto-memory dir (`~/.claude/projects/<project>/memory/`)`. Three subtypes:
- **Feedback memory** (`feedback_*.md`) — behavioral guidance about how Claude should work (e.g., *"validate before execute"*, *"surface alternatives before deciding"*, *"separation of concerns over Swiss Army knives"*)
- **User memory** (`user_*.md`) — Akash identity facts, role, expertise, preferences (e.g., *"uses first-principles framing"*, *"PM mental model"*)
- **Project memory** (`project_*.md`) — ephemeral project state, current sprint, what's blocked

**Routing guardrail — global memory = cross-context only.** Before filing anything as memory, apply the cross-context test: does this apply to *every kind of work*, or only to one domain/craft? Domain-specific craft lessons (resume voice, cover-note story-structure, a skill's house style) route to the **relevant skill/OS**, NOT global memory. Global memory is for cross-context behavior + identity only. (Lesson from 2026-06-29: a cover-note craft lesson was mis-filed as global feedback memory when it belonged in the OS cover-letter skill.)

**B. Wiki content.** Delegated to `/archie-ingest`. Same SCHEMA 12-step flow.
- Session source page (CONVERSATION source type) — captures the design conversation
- New concept / entity / idea / project pages this session produced
- Updates to existing wiki pages (incremental update discipline applies)

**C. Harness candidates.** Surface as proposed Edits for approval. Never auto-write.
- New skill SKILL.md files (`~/.claude/skills/*/SKILL.md`)
- Modified existing SKILL.md files
- Hook configurations (`~/.claude/hooks/`)
- AGENTS.md / CLAUDE.md edits

**D. Output→wiki promotions.** Per Aakash Gupta's pattern: outputs start ephemeral; promote when they earn it.
- Briefings or syntheses worth long-term reference
- Query answers (from `/archie-query`'s `outputs/` folder) that proved valuable enough to re-read

### 3. Discuss-before-compile checkpoint — CHECKPOINT, do not skip

**Adaptive — show only what's there.** Lead with the categories that have candidates; collapse empty ones to a single line (or omit). Don't make Akash wade through "A: none / B: none / C: none" structure — that's the "cumbersome and annoying" failure mode. A session that only produced wiki + harness content shows two sections, not four.

Surface to Akash, by category, skipping any that are empty:
- **A. Memory candidates:** list with proposed file destinations and one-line content summaries
- **B. Wiki content scope:** what `/archie-ingest` will write (source page, new pages, updates); follow `/archie-ingest`'s own checkpoint discipline
- **C. Harness candidates:** list with file paths and proposed Edit summaries; full diff available on request
- **D. Output promotions:** list of candidates and proposed destinations

Wait for Akash to direct: which categories to write, which candidates within each to approve, which to defer.

### 4. Execute approved writes

- **A. Memory:** if Akash approves, write each as a discrete memory file per the auto-memory convention (frontmatter with name/description/type/metadata; body with rule + Why + How to apply). Update `MEMORY.md` index.
- **B. Wiki:** delegate to `/archie-ingest`. It runs its own 12-step flow including its own checkpoint. Pass the session content with explicit incremental-delta context if applicable.
- **C. Harness:** apply approved Edits one at a time (per-file approval). Tier 1 files trigger the hook normally.
- **D. Outputs:** write to `wiki/` via `/archie-ingest`'s pattern.
- **E. SESSION.md + counts (shift-left — keeps `/orient` drift-free):** if the session changed recent history or open priorities, refresh `~/.claude/knowledge/SESSION.md` (add a "What Happened" entry, update Open Priorities) AND bump the mechanical counts in `index.md` / `entities.json` for anything written this session. **Gated on relevance** — a shallow capture that changed neither doesn't touch SESSION.md. This is a *step within session-ingest*, not its identity: session-ingest captures a Claude Code session; updating SESSION.md is one of its closeout actions, not what it "is." Prevents the drift `/orient` would otherwise have to flag.

### 5. Post-ingest audit

- Verify all approved categories were actually written (re-read each touched artifact)
- List any deferred items Akash explicitly said "do this later"
- **Stamp the deterministic session marker** — write `session-id: <YYYY-MM-DD-NN>` into the session source page Timeline AND the `log.md` line, so any later incremental run finds this capture by exact match instead of guessing (per step 1)
- Update the session source page Timeline with what was captured and what was deferred
- Append `log.md` entry combining all categories under one session-ingest header, including the `session-id` marker

## Output format

```
## Session Ingest — [session title or descriptor]

**Scope:** [full session | incremental delta from <previous-ingest> | partial capture of <subset>]
**Boundary (if incremental):** Previous captured up to: <X>. New content since: <Y>.

### A. Memory candidates
- [feedback / user / project candidates with proposed memory file + one-line summary]

### B. Wiki content (will delegate to /archie-ingest)
- Source page: <slug>
- New pages: [list]
- Updates: [list with incremental-update tag where applicable]

### C. Harness candidates
- [proposed Edits with file paths + summaries]

### D. Output→wiki promotions
- [outputs worth promoting]

— pause for Akash's approval per category —

### Written (after approval)
- Memory: [files written]
- Wiki: [pages touched via /archie-ingest]
- Harness: [files modified]
- Outputs: [pages promoted]

### Deferred
- [things Akash said "do this later"]
```

End with: `Session ingested. <N> memory + <M> wiki + <K> harness + <L> outputs = <total> writes across the four categories.`

## Why this skill exists

Per `wiki/idea/archie-usage-layer.md` v1+ queue (originally named `/archive-session`, renamed to `/session-ingest` 2026-05-20 for verb-pattern consistency with `/archie-ingest`). Sessions are the highest-yield CONVERSATION sources because they produce multiple artifact categories simultaneously. Without this skill, the failure mode is: deep work happens in a chat, the chat ends, the learnings evaporate. `/archie-ingest` alone captures the wiki portion but misses the memory + harness + output dimensions.

The architectural principle is composition: `/session-ingest` adds session-specific orchestration on top; the universal wiki-write primitive stays in `/archie-ingest`. Don't conflate.

Companions: [[skill-archie-ingest]] (universal write-side primitive — delegated to for wiki writes), [[skill-archie-query]] (read-side), [[skill-orient]] (session-start ritual; also surfaces /session-ingest in its Companions block), future `/archie-audit`, `/archie-eval`, `/archie-corpus-mine`.
