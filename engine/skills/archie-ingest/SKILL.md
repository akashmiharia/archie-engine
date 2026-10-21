---
name: archie-ingest
description: Use whenever Akash wants to ingest content into Archie — anything he wants the wiki to learn from. Triggers on phrases like "ingest this", "add to archie", "save this to the wiki", "process this transcript", "this article is worth keeping", "let's archive this", or when he pastes substantial content (article, transcript, observation, deck excerpt) and signals he wants it in the brain. Also triggers on a URL or file path passed with intent to ingest — article links, YouTube videos, PDFs, decks, screenshots, transcripts in any form, his own LinkedIn / Substack / Twitter writing, email threads, paywalled-article PDFs. Routes through PREPROCESSORS.md for format conversion if needed, then runs the canonical 12-step SCHEMA flow with a mandatory "discuss before compiling" checkpoint. Per SCHEMA.md: one source typically touches 10-15 pages — if your ingest only touches one, the ingest is incomplete. Never auto-installs preprocessor tools. Never fabricates speaker attributions on unnamed transcripts. Never drifts to web search to pad content.
---

# Archie Ingest — single-source content into the wiki

The skill that mechanizes Archie's write-side. Pairs with `/archie-query` (read-side) to close the brain-first loop. Per `wiki/concept/canonicalization-as-meaning.md`: manual filing kills personal KBs. The wiki succeeds when the LLM does canonicalization automatically, using `index.md` + `entities.json` + closed-vocabulary tags as the routing substrate. This skill is how that happens.

**Reference, don't pair.** This skill orchestrates the flow. Format conversion lives in separate deterministic scripts mapped via `~/.claude/knowledge/PREPROCESSORS.md`. Per `wiki/concept/llm-wiki-pattern.md` (the deterministic-script-plus-agent split lifted from gbrain): script does I/O and structure, agent does substantive analysis. Don't collapse the split.

## Hard rules — anti-patterns to never violate

- **No silent guessing on speakers.** If a transcript has unnamed speakers and derivation confidence is low, ASK before attributing. Hallucinated attributions break canonicalization discipline.
- **No fabrication.** If the source has part of an answer, name the gap, don't fill it with plausible-sounding content.
- **No auto-install.** Preprocessor tools (MinerU, WhisperX, yt-dlp, Firecrawl MCP, etc.) get surfaced with install commands but never installed without Akash's confirmation. `pip install`, `npm install -g`, `brew install` are blast-radius actions.
- **No web search drift.** Brain-first. If the source doesn't have something, say so. Don't pad ingested content with external assertions.
- **No raw-folder edits.** `raw/` is immutable. Preprocessed output goes to `raw/processed/`. Extracted images go to `raw/assets/`. Originals are never modified.
- **No one-page ingests.** Per SCHEMA.md: one source typically touches 10-15 pages. If your ingest only touches the source page itself, you're filing, not compounding. Re-examine before completing.
- **No skipping the discuss-before-compile checkpoint.** Surface takeaways to Akash before writing pages. Literal pause, not a guideline.
  - **Exception, only in his words:** if Akash explicitly waives it ("use your lean," "don't ask me questions"), proceed and surface the routing plan inside the ingest report instead. A waiver covers the run it was given for, not the next source. Inferred permission is not a waiver.
- **Read fully before categorizing.** Categorization is the *output* of comprehension, never a substitute for it. No routing decision from a skim. (See "Categorize first" below.)
- **Multi-label by default.** A source can — and a rich one does — touch many page-types. Never force one bucket; single-label thinking is the main cause of mis-routing.
- **In batch, rich/ambiguous sources are never fast-pathed.** Triage's job is partly to *spot* which sources need the full individual deep-read and flag them for it.
- **No timestamp-bump updates.** Touching `last_updated` on a page without adding meaningful content is filing, not compounding. If you can't name what changed in the Timeline section, don't update the page.
- **Extract before synthesize.** For ANY non-text source (URL, PDF, deck, audio, video, image), the deterministic extraction layer (Firecrawl-scrape / MinerU / WhisperX per `PREPROCESSORS.md`) runs FIRST and returns cleaned markdown before any agent synthesis. **No exceptions.** Per gbrain's deterministic-script-plus-agent split (see `wiki/concept/preprocessor-pattern.md` and `wiki/concept/llm-wiki-pattern.md`): skipping extraction wastes 4-32× the tokens AND introduces noise into canonicalization. The agent never reads raw HTML, raw audio, or raw binary directly — only the cleaned extract.
- **If the source is the current Claude Code session, prefer `/session-ingest`.** This skill handles single external sources (article, transcript, deck, file, URL). `/session-ingest` is the sibling that wraps memory routing + harness changes + output→wiki promotions around the wiki-write portion, then delegates that wiki write back to this skill.

## Decision points — when to ask, when to proceed

| Situation | Action |
|---|---|
| Source format needs a preprocessor not installed | Surface install command, wait for confirmation |
| Transcript with named speakers | Extract names, resolve via `entities.json`, proceed |
| Transcript with unnamed speakers, derivation high-confidence | Attribute + flag in source page that attribution was inferred |
| Transcript with unnamed speakers, derivation low-confidence | Ask Akash to confirm before attributing |
| New entity (person, company, tool) not in `entities.json` | Surface for approval before creating canonical entry |
| Sensitive entity (family, partner, work-confidential person) | Pause and flag privacy implications before writing |
| URL is LinkedIn / X / Instagram post | Suggest manual paste of the text; do not attempt automated scraping (ToS Section 8.2 + account-flag risk) |
| URL returns thin content or 403 | Try fallback chain (WebFetch → Firecrawl MCP → Stagehand) before giving up |
| Synthesis would touch 0-1 pages | Stop and re-examine; one-page ingests are incomplete |
| Source touches a tag candidate accumulating in `log.md` (e.g. `read-side`, `career`) | Note in log; do not silently add new tags — closed vocabulary requires SCHEMA upgrade discussion |
| Source updates an existing page where the new content doesn't change understanding | Timeline append only; do not rewrite Compiled Truth |
| Source updates an existing page where Compiled Truth genuinely shifts | Rewrite Compiled Truth, preserve the prior interpretation in Timeline with date + reason |
| Source is the current Claude Code session | Hand off to `/session-ingest` (sibling skill). It handles memory + harness + output promotions then delegates the wiki-write portion back here. |

## Learning-derivation framework (what an external source can produce)

External sources (articles, transcripts, decks, files, URLs) produce wiki content along these universal categories. The skill enumerates which categories the source touches before writing — that's how canonicalization routing works without manual filing.

| Category | Looks like | Routes to |
|---|---|---|
| **Source material** | The source itself as the canonical snapshot of what was read/watched/absorbed | Source page (`wiki/source/`) — always created |
| **Conceptual insights** | New named pattern, refined principle, framework articulated in the source | Concept page (`wiki/concept/`) — create or timeline-append |
| **Entity updates** | New people / companies / tools introduced; updates to existing entities | Entity page (`wiki/entity/`) — create or timeline-append |
| **Productive speculation** | Idea sparked by the source, not yet committed | Idea page (`wiki/idea/`) — create or timeline-append |
| **Build outcomes (rare for external sources)** | The source documents a project or initiative | Project page (`wiki/project/`) — create or timeline-append |
| **Tech-stack signal** | The source recommends, deprecates, or benchmarks a tool — may shift a primary pick | Tool entity (`wiki/entity/tool-*.md`); `PREPROCESSORS.md` update if it changes a primary |
| **Cross-cutting connections** | New `[[wiki-link]]` relationships between existing pages | Cross-reference additions across affected pages |

**The categories are derivations, not requirements.** Not every source touches every category. A focused article may only produce a source page + one concept update. A book ingest may produce 15-20 page touches across all categories. Match scope to source; don't pad to hit categories.

**For session sources (the chat itself, not an external artifact), use `/session-ingest` instead.** Sessions add three categories this skill doesn't handle: memory routing (Claude-side feedback, Akash-identity facts, project state), harness changes (skill / hook / AGENTS.md edits), and output→wiki promotions. `/session-ingest` handles those, then delegates the wiki-write portion back here. Composition over conflation.

## Categorize first — the routing pass (before any writing)

Categorization is **the output of reading, never a substitute for it.** Read the source fully first, then categorize. Categorization is "now that I understand it, here is everywhere it lands" — nothing gets routed from a skim. This is what keeps the feature *stronger*, not weaker: it adds a structuring layer on top of the same deep read, it never replaces the read.

It is a **two-sided match**, not a one-sided read of the incoming source:
- **Outward (the source):** what knowledge is in here, which page-types (the Learning-derivation categories above) does it touch?
- **Inward (Archie):** what already exists that this overlaps with, embeds into, or contradicts? This is canonicalization using the registry as routing substrate (`index.md` + `entities.json` + closed-vocabulary tags), per [[canonicalization-as-meaning]].

The match between the two sides **is** the routing decision: for each chunk of knowledge → an existing page (which one, which disposition) or a new page (which type).

**Two rules that keep this strengthening ingestion, not weakening it:**
1. **Multi-label by default. Never force one bucket.** A rich source (e.g. a 1:1 transcript covering career + product + metrics + hiring + eng next steps + requirements) is *correctly* categorized as touching all of them, and gets ingested across all of them. Single-label thinking is the main cause of mis-routing.
2. **The inward look is tiered for cost — but only on Archie's side, never the source's.** The source is always fully read. Economize only on which *existing* pages you pull:
   - **Cheap, for everything:** read `index.md` one-liners + `entities.json` — enough to know what exists and roughly where.
   - **Deeper, only for flagged overlaps:** read the TLDR / Compiled Truth of the specific pages the cheap scan says collide, to decide rewrite vs append precisely.
   - **Never** blanket-read full pages.

**Disposition — the 3 moves.** For each existing page a source touches, pick one. Recency is the *input* to this choice, not a separate step (old is not the same as wrong):

| Move | When | Treatment |
|---|---|---|
| **Rewrite** | Source is current truth that shifts understanding | Rewrite Compiled Truth in depth (the latest-and-greatest, most detail); preserve the prior interpretation in Timeline with date + reason |
| **Append-dated** | Source is historical-but-still-valid, or adds evidence without shifting understanding | Add a dated Timeline entry; Compiled Truth stays intact (this is the evolution log — how thinking got here) |
| **Skip-and-log** | Source is fully stale / superseded | No page touch beyond a `log.md` line (optionally a "deprecated as of DATE" note on the page) |

Depth and treatment can vary by page type — a `project/` page logs evolution differently than an `entity/` or `concept/` page.

**Scales by source count:**
- **1 source:** light categorization — which page-types it touches, embed-into-existing vs create-net-new, disposition per touched page.
- **N sources (batch):** the same, plus a triage matrix *across* the pile (see "Batch mode" in the flow) — categorize sources against each other AND against the existing wiki, so overlap and ordering are resolved before any expensive deep-write.

## The flow

### 0. Detect source type — and count sources

If more than one source was handed over (a folder, a list of files/URLs, a pile of pastes), **run Batch mode (step 5) first** — triage the whole pile before deep-processing any single one. For a single source, proceed straight through.

The argument to `/archie-ingest` is one of:
- **URL** — disambiguate by domain (see URL routing below)
- **File path** — local file, look up format in `PREPROCESSORS.md`
- **Pasted text inline** — check if transcript-shaped, otherwise straight to synthesis
- **Nothing** — ask Akash what he's ingesting

If unclear, ask. Don't guess source type.

### 1. Extract — mandatory for non-text sources (deterministic script path, runs FIRST)

For any non-text source, the extraction layer runs FIRST. **Not optional.** The agent does not proceed to step 2 (discuss-before-compile) until the deterministic extraction returns cleaned markdown. This enforces the gbrain deterministic-script-plus-agent split per [[preprocessor-pattern]].

Look up the format in `~/.claude/knowledge/PREPROCESSORS.md` — that table is the load-bearing dependency surface. The skill orchestrates; the table provides the tool. Don't hardcode tool names here.

Standard routing (current as of 2026-05-22; PREPROCESSORS.md is canonical):
- **PDF / PPTX / DOCX / XLSX / image** → invoke MinerU → cleaned markdown to `raw/processed/`
- **Audio file** → invoke WhisperX with diarization → diarized transcript
- **Video file** → invoke yt-dlp (audio extract) → WhisperX
- **YouTube URL** → invoke yt-dlp → WhisperX
- **Generic web URL** → invoke `firecrawl-scrape` skill (or Firecrawl MCP `npx -y firecrawl-mcp`); fallback to Crawl4AI per PREPROCESSORS.md vendor-independence path if Firecrawl fails
- **Social URL** (LinkedIn / X / Instagram) → ToS-prohibited automated scraping; ask Akash for manual paste of the post text
- **Already-text source** (paste-through, `.md`, `.txt`) → no extraction needed; proceed to step 2

If a required preprocessor is not installed, surface the install command and **wait for confirmation** before installing. Never auto-install (`pip install`, `npm install -g`, `brew install` are blast-radius actions per the hard rule).

Preprocessor output lands at `raw/processed/<slug>.md` (immutable original preserved at `raw/<original-name>`; extracted images at `raw/assets/`). The agent then reads ONLY the cleaned markdown for synthesis — never the raw original.

### 2. Read fully → categorize → checkpoint, do not skip

By this point you have **read the full source** (or its cleaned extract) and run the categorization routing pass (per "Categorize first" above): outward = which page-types it touches, inward = which existing pages it collides with (cheap `index.md`/`entities.json` scan, then deeper read only on flagged overlaps). The checkpoint surfaces that categorization — it is not a skim.

Surface to Akash:
- **TLDR** of the source (1 sentence)
- **3-5 key takeaways**
- **Routing plan** — the output of categorization: each chunk of knowledge mapped to either an existing page (which one + which of the 3 disposition moves: rewrite / append-dated / skip-log) or a new page (which type). Multi-label is expected; a rich source lights up many destinations.
- **Entities and concepts touched** (with proposed canonical names from `entities.json` checks)
- **Open questions or potential contradictions** with existing wiki content
- **Whether the source could graduate to project page** (if it documents a substantive shipped outcome)
- **Scope decision request:** "Recommended scope is X pages touched. Maximalist would be Y. Minimal would be Z." Let Akash pick.

Wait for Akash to direct framing, correct names, flag scope, choose maximalist vs recommended vs minimal. Do not start writing pages yet.

### 3. The canonical 12-step flow (per SCHEMA.md §Ingest)

After Akash's direction:

1. **Classify** the source — one of 8 codes: ARTICLE | PAPER | BOOK | TALK | CONVERSATION | OBSERVATION | INDUSTRY | INTERNAL
2. **Read** the source (or preprocessed output) fully
3. **Identify** entities and concepts touched
4. **Check `entities.json`** for canonical names; surface any new entities for approval
5. **Check `index.md`** for existing pages that this source updates or contradicts
6. **Create source page** at `wiki/source/<slug>.md` per SCHEMA template (TLDR, Key Extractions, Connections, Open Questions; no Timeline — sources are snapshots)
7. **Update or create concept and entity pages** this source informs — **aim for 10-15 page touches** (more if Akash explicitly authorized maximalist scope in step 2). For each existing page being updated, apply the **3-move disposition** from the routing plan (see "Categorize first"):
   - **Read the current Compiled Truth section.** Classify the source's relationship to it: current-truth-that-shifts-understanding (**rewrite**), historical-but-valid or adds-evidence (**append-dated**), or stale/superseded (**skip-and-log**).
   - **Append-dated is the common move.** Add `- YYYY-MM-DD: <what this source added>` to the Timeline. Compiled Truth stays intact — this is the evolution log.
   - **Rewrite is the heavier move.** Only when understanding genuinely shifts. Rewrite Compiled Truth in depth (latest-and-greatest), and preserve the prior interpretation in Timeline with date + reason. Erasure drift is a real failure mode.
   - **Skip-and-log** when the source is fully superseded — `log.md` line only, optionally a "deprecated as of DATE" note.
   - **Name what changed.** Every update should answer "what did this source add or change here?" If you can't name it, it isn't earning the timestamp bump — skip it.
8. **Add cross-references** between related pages using `[[wiki-link]]` style
9. **Update `index.md`** — sorted by type, then alphabetical within type
10. **Append to `log.md`** with format: `## [YYYY-MM-DD] ingest | <source title> | touched <N> pages`
11. **Update `entities.json`** if new entities were approved in step 4
12. **Post-ingest audit** — re-read each touched page and verify it was actually updated meaningfully, not just timestamp-bumped

### 4. Transcript handling (special path within steps 2-3)

If the source is a transcript (paste-through or preprocessed audio):

- **Named speakers** ("Peter: ...", "Akash said: ..."): extract names, resolve each against `entities.json`. If new, surface for approval per step 4 above.
- **Unnamed speakers** ("Speaker 1: ...", "[00:42] ..."): attempt derivation using context — PM vocabulary, references to known projects/people from `AKASH.md`, dialogue rhythm, first-person identity markers.
  - **High confidence** → attribute, flag in source page that attribution was inferred (not stated)
  - **Low confidence** → ask Akash to confirm before attributing
- **Verbatim quotes belong in source pages only.** Concept and entity pages hold compiled meaning, not direct quotes (per `wiki/concept/canonicalization-as-meaning.md`).

### 5. Batch mode — more than one source

When several sources arrive together, do **not** deep-process them one-by-one cold. That's how you ingest source #1 deeply, then discover source #14 supersedes it and the work was wasted. Work like a data scientist: structure first, then process — cheap planning pass across the whole pile *before* the expensive per-source writes.

**Triage pass (cheap, across the whole pile):**
1. **Inventory.** List every source with a one-line "what is this."
2. **Lightweight classify** each: type (ARTICLE / TALK / CONVERSATION / …), the page-types it touches (multi-label), and a first-cut disposition guess (rewrite / append / skip).
3. **Flag the rich/ambiguous ones for full individual deep-read.** Triage's job is partly to *spot* which sources are too meaty to fast-path. A multi-topic 1:1 transcript never gets the quick treatment.
4. **Resolve overlap & ordering across sources** — which sources hit the same pages, which supersede which, what order avoids rework. Categorize sources against each other AND against the existing wiki (cheap `index.md`/`entities.json` scan).
5. **Produce one batch routing plan**, grouped by *category of knowledge* (so related sources land together), and surface it at the step-2 checkpoint as a single plan rather than N separate ones.

**Then deep-read and ingest in the planned order**, running the normal per-source flow (steps 1-4) for each. The triage plan is a plan, not a contract — if a deep read surfaces a category triage missed, add it; the post-ingest audit (step 12) catches drops.

Checkpoints in batch mode are abbreviated: approve the batch plan once up front, then surface only deviations and surprises per source rather than a full checkpoint each time.

## Output format

```
## Ingest — [source title]

**Source type:** [ARTICLE | PAPER | BOOK | TALK | CONVERSATION | OBSERVATION | INDUSTRY | INTERNAL]
**Source page:** wiki/source/<slug>.md
**Pages touched:** [N]

### Created
- [list of new pages with one-line descriptions]

### Updated
- [list of updated pages with what was added]

### Entities
- [new entities added to entities.json, or "none"]

### Cross-references added
- [N links, sample of the most-important]

### log.md entry
[the line appended]

### Audit
[any concerns surfaced during step 12 — stale claims now contradicting, gaps revealed, tag candidates noted, incremental-update verifications]
```

End with: `Ingested. <N> pages touched.` (Or, if touch count < 5: `Light ingest — only <N> pages touched. Worth pressure-testing whether this source earns a full canonicalization or stays as a one-off.` Or, if maximalist scope was authorized: `Ingested. <N> pages touched. Maximalist scope per Akash's direction; worth reviewing whether full-page-per-tool earned its weight or if alternatives could have stayed inline.`)

## Why this skill exists

Per `wiki/idea/archie-usage-layer.md`: capture cadence dies under friction. The wiki's value comes from one source touching 10-15 pages, not one. Manual filing is the cognitive cost that kills personal KBs (per `wiki/concept/canonicalization-as-meaning.md`). This skill removes filing as a manual act — the LLM does canonicalization automatically using the registry as routing substrate.

Companions: `/archie-query` (read-side), `/session-ingest` (the sibling that handles session sources — wraps memory + harness + output promotions around the wiki write, then delegates the wiki portion back here), `/archie-audit` (parked), `/archie-eval` (parked), `/archie-corpus-mine` (parked — bulk LinkedIn / Instagram / TikTok exports). Each sibling has a different I/O profile and earns its own skill.
