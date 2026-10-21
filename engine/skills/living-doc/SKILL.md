---
name: living-doc
description: De-stale and maintain (or create) a living document — read the existing doc PLUS the recent updates/threads/context Akash drops in, reconcile them, and rewrite it so only the relevant, time-bounded changes land in a clean, useful structure (problem→solution, open questions, next steps, decisions, metrics). Notion-first (the AI-OS mirror lives there), but works on any target — a Google Doc, a local markdown file, a tags doc, a Substack draft outline. Triggers on "update this Notion page with this context", "this doc is stale, fold in these notes", "turn these threads into a [doc]", "keep this page current", "reconcile this doc with what's changed". Single page OR a parent/child collection.
disable-model-invocation: false
user-invocable: true
---

# /living-doc — De-stale & Maintain (or Create) a Living Doc

Two modes, one engine. The job: take scattered, time-spread inputs — a stale doc plus a pile of recent notes/threads/context, or just the pile — and produce or refresh **one clean doc** that reflects the current truth, that someone can read in three minutes and know where things stand.

Built for Akash's actual surfaces: a **Notion page** (the AI-OS mirror, project pages, content planning), a **Google Doc**, a **local markdown file**, or any single doc you point it at. It is target-agnostic by design — the reconcile-and-restructure engine is the same; only the read/write adapter changes.

## When to use

- **Update / de-stale (the common case):** "Here's a Notion page with a lot of history, but a bunch has changed. Read it + these updates, fold in what's still relevant, drop the stale stuff, restructure it so it's actually useful."
- **Create:** "A lot happened across these notes and there's no doc yet — structure it into a [status / plan / brief / research doc]."

## Mode detection

- A target doc/page is provided → **UPDATE mode**.
- No target, only raw inputs → **CREATE mode** (which produces a doc that then lives in UPDATE mode forever after).

If the doc *type* is unclear (status vs plan vs brief vs research), ask — it tunes the structure.

## Target adapters (how it reads + writes)

- **Notion page** — read via the Notion MCP `fetch`; write via `update-page`. Honor the [[notion-mcp-tooling]] memory: real newlines (not `\n`), never `allow_deleting_content` to bypass the child-page guard. For token-cheap deterministic edits (append a block, single section), prefer direct REST + token per `~/.claude/rules/tool-selection.md`.
- **Google Doc** — read/write via the Google Drive MCP (`read_file_content` / `create_file`/update).
- **Local markdown / tags doc** — Read + Edit/Write directly.
- **Multi-page Notion collection** — a parent page + child pages (e.g. a project umbrella + sub-pages). Read the parent + its children; keep the set consistent.

## Page scope — single page or a tree

- **Discover the set PROACTIVELY — never just trust the named pages.** Read the parent + its children, AND search the workspace for topically-relevant pages by name/keyword. Akash names a few; there are often more — the right home for a chunk of content is frequently a page he didn't mention. **Missing the right page is the #1 failure mode of this skill** (work's first eval failed exactly here). When you find a candidate, open it and check whether the content belongs before deciding.
- **Route to the MOST SPECIFIC home.** Detail belongs on the page that *owns* it, not on the umbrella/index (which holds one-line summary + status + link per child). Before defaulting to the index, ask: "what is the most specific page that owns this?"
- **An update often corrects the target, not just adds to it.** New info frequently makes existing content stale. Flag and fix the contradiction, don't just append.
- **Keep the set consistent:** the umbrella carries only a one-line summary + status + link per child — update it when a child's summary/status/link changes, never by duplicating child detail upward. Keep cross-links intact.

## Hard rules — anti-patterns to never violate

- **Don't lose load-bearing history.** De-staling ≠ deleting context. Keep the history that still explains *why*; cut only what's genuinely obsolete or superseded. When unsure, preserve and date it.
- **Time-bound the updates.** Fold in only changes relevant to the current state; tag what changed and when. Don't dump every thread verbatim.
- **Checkpoint before writing.** Surface the proposed delta — what's added, what's cut as stale (and why), what's still unresolved — before editing. Literal pause, not a guideline.
- **Preserve structure on write-back.** Match the target's native format. Notion: real newlines, re-fetch before write, respect the child-page guard. Don't round-trip through a converter that flattens structure.
- **No fabrication.** If an update is ambiguous or a metric is missing, name the gap — don't invent. Cite where each fact came from.
- **Decisions get logged; open items get owners.** Material decisions land with date + why so they're not relitigated. Every open item carries an owner + status.
- **Voice.** When the doc is Akash-facing or Akash-authored (content drafts, his own pages), apply the [[referencing-others-materials]] discipline — adapt any borrowed structure through his voice; anchor on his own prior work. No em dashes per AGENTS.md.

## Default doc skeleton (tune by type)

- **Problem → Solution** — the framing; what's shipping or proposed
- **Open questions** — unresolved, each with an owner
- **Next steps** — who / what / when
- **Recent updates** — time-bounded; what changed since last, dated
- **Decision log** — date + decision + why
- **Metrics / data / research** — each with its source
- **Owners / stakeholders**
- **Links**

Type tuning: status doc leans recent-updates + next-steps; plan leans sequencing + bets; brief leans problem + decision; research leans findings + data + sources.

## Flow

1. **Detect mode** (target provided? update : create), **doc type** (ask if unclear), **target adapter** (Notion / Google Doc / local), and **page scope** (single or a tree).
2. **Gather inputs.** Read the target doc(s) fully + every provided update/thread/note.
3. **Extract** from the inputs: decisions, open items (+ owner/status), next steps, status changes, metrics/data, new stakeholders, risks.
4. **Reconcile + route** (update mode): map each extracted item against the existing doc — *new* / *changes understanding* / *now stale* / *still-relevant history* — and, for a tree, to its home page. Decide keep vs cut vs supersede. (Create mode: just structure the extractions.)
5. **CHECKPOINT:** surface the proposed delta — added, cut-as-stale (with reasons), still-open, doc-type structure, and (multi-page) which pages get touched. Wait for direction.
6. **Write:** update in place (target's native format) or create. For a set, keep the umbrella summaries + cross-links consistent. Log decisions, date the recent-updates, flag new open items with owners.
7. **Report:** what changed, what was cut and why, what's still open, which pages were touched.

## Output format

```
## Living-doc — [doc title]
**Mode:** update (de-stale) | create     **Type:** status | plan | brief | research
**Target:** [Notion page / Google Doc / path, or "new"]

### Folded in (relevant, time-bounded)
- [updates that landed, dated, with source]

### Cut as stale / superseded
- [what was removed and why]

### Still open
- [open questions / next steps with owners]

### Written
- [where; what sections changed]
```

## Status

v0.1 — re-authored personal-native on 2026-06-07; Notion-first, any-target.

**What work's first eval surfaced (carried into this fork):** the skill took the user's *named* pages at face value and missed the page the content most belonged on. Hence the "discover the set proactively" + "route to the most specific home" + "updates often correct, not just append" rules above. Keep eval'ing on real docs; tune from each miss. Differentiation accrues as it learns Akash's structure and judgment from the docs it touches — it doesn't pretend to know them on day one.
