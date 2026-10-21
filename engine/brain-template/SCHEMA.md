# Archie — Knowledge Base Schema (engine template v1)

> Archie is a compounding personal knowledge base run by a human and an AI agent together. The name comes from Alan Emtage's 1990 Archie, the first internet search index. This template is the engine's generic schema; the brain built on it belongs to the machine it lives on.
>
> Synthesized from three reference patterns (Andrej Karpathy's LLM Wiki gist, Aakash Gupta's PM Second Brain, Garry Tan's gbrain, all April 2026) and hardened over six months of daily use on the original brain.
>
> Co-evolved by the human and the agent. The agent reads this before any knowledge operation. Schema upgrades happen through discussion, then this file is rewritten and the discussion becomes a wiki page.

---

## How this brain behaves

Four commitments, in order:

1. **Curious.** A gap is a prompt, not a failure. When a question reveals something missing, say so and name what would fill it.
2. **Ever-evolving.** Compiled truth is rewritten when evidence changes. Nothing here is set in stone, including this file.
3. **Fact-checking.** Every claim traces to a source in `raw/` or a logged session. Seeded pages (those with a `craft_seed:` field) arrived from another brain with their `origin:` and `applies_when:` stated; treat them as hypotheses to test in this context, not rules.
4. **Continuous integration.** Small ingests, often. The brain is only as good as the habit of feeding it.

## First Principles

Two splits do all the work:

1. **Receptive vs productive.** Pages either capture what exists in the world that you are learning (receptive: source, concept, entity) or what does not yet exist that you might bring into being (productive: idea, project). Different lifecycle, different shape.
2. **Compiled truth vs timeline.** Long-lived pages have a top section (current best understanding, mutable, rewritten when evidence changes) and a bottom section (append-only timeline of evidence). Source pages are the exception: snapshots, not evolutions.

## Architecture

```
~/.claude/knowledge/
  SCHEMA.md          ← you are here. Rules.
  index.md           ← catalog. Read first to navigate.
  log.md             ← append-only history of every operation.
  entities.json      ← canonical entity names + aliases. Prevents duplicates.
  SESSION.md         ← the cockpit: open priorities, active focus, parked backlog.
  PREPROCESSORS.md   ← format → extraction tool table for non-text sources.
  audit.sh           ← deterministic regression audit; run after structural changes.
  raw/               ← immutable source material. The agent reads, never modifies.
  wiki/              ← agent-maintained pages. The agent owns this directory.
    source/          ← one page per ingested source.
    concept/         ← receptive synthesis.
    entity/          ← named things (people, tools, companies, resources).
    idea/            ← productive speculation, pre-commitment.
    project/         ← productive commitment, builds + learnings.
  outputs/           ← generated answers, briefings, drafts. Throwaway by default.
```

Mode workspaces (a PM kit, a build folder, a content folder) read from Archie and keep their own operational state on top. **Goals, sprints, and OKRs live in `SESSION.md` or the workspace, not in wiki pages.** Archie is the substrate.

## Page Types (5)

### 1. Source `wiki/source/[slug].md`
What you read, watched, or absorbed. One per source. Snapshots, not evolutions.

```yaml
---
type: source
title: [Title]
source_type: ARTICLE | PAPER | BOOK | TALK | CONVERSATION | OBSERVATION | INDUSTRY | INTERNAL
date_added: YYYY-MM-DD
original_url: [URL if applicable]
author: [Author or "self"]
confidence: high | medium | low
tags: [closed-vocabulary tags, see §Tags]
---

## TLDR
One sentence.

## Key Extractions
[Bullets: facts, quotes, decisions. Preserve direct quotes for key claims.]

## Connections
[Existing wiki pages this updates or contradicts.]

## Open Questions
[What this source leaves unresolved.]
```

No timeline section. Sources are immutable interpretations of a moment.

### 2. Concept `wiki/concept/[slug].md`
Receptive. Synthesized understanding of something that exists in the world. Compounds across sources.

```yaml
---
type: concept
title: [Concept Name]
sources: [source-slug-1, ...]
related: [other concepts and entities]
confidence: high | medium | low
last_updated: YYYY-MM-DD
tags: [...]
---

## Compiled Truth
## Where Sources Agree
## Where Sources Conflict
## Open Questions

---

## Timeline
- YYYY-MM-DD: ingested [source X], updated section Y
```

### 3. Entity `wiki/entity/[type-slug].md`
Receptive. A named thing: person, tool, company, concept-author, competitor, resource. Canonicalized via `entities.json`.

```yaml
---
type: entity
entity_type: person | tool | company | concept-author | competitor | resource
name: [Canonical name]
aliases: [...]
sources: [...]
last_updated: YYYY-MM-DD
tags: [...]
---

## Compiled Truth
(person: what drives them, what they are working on, relationship state. tool: what it does, when to use it, where it falls short. company: positioning, recent moves. resource: what entitlement you hold and what it unlocks.)

---

## Timeline
```

### 4. Idea `wiki/idea/[slug].md`
Productive, pre-commitment. Lifecycle: dormant → active → shipped (graduates to project) | killed.

```yaml
---
type: idea
title: [Idea Name]
status: dormant | active | shipped | killed
lens: [the framework you are looking through]
sparked_from: [concepts and entities that collided]
related_projects: [...]
last_touched: YYYY-MM-DD
tags: [...]
---

## The Spark
## The Lens
## What It Is
## Dependencies
## What Would Make It Real
## Why I'm Not Working On It Right Now

---

## Timeline
```

### 5. Project `wiki/project/[slug].md`
Productive, committed. What you built or are building.

```yaml
---
type: project
title: [Project Name]
status: in-progress | shipped | paused | abandoned
date_started: YYYY-MM-DD
date_completed: [if shipped]
graduated_from_idea: [if applicable]
related_ideas: [...]
sources_referenced: [...]
last_updated: YYYY-MM-DD
tags: [...]
---

## Compiled Truth
[Goal, approach, what worked, what failed, learnings.]

## What I'd Do Differently
## Cross-References

---

## Timeline
```

## Source Classification (8 types)

| Code | What it is |
|---|---|
| ARTICLE | Articles, blog posts, gists, newsletters |
| PAPER | Academic or technical papers |
| BOOK | Books, long-form |
| TALK | Podcast, video, interview transcripts |
| CONVERSATION | Chat exports, meeting notes, 1:1 transcripts |
| OBSERVATION | Your own raw notes, journal, real-time captures |
| INDUSTRY | Market intel, competitor moves, sector news |
| INTERNAL | Past decisions, retros, build logs not yet promoted to project pages |

## Tags

A page can carry one or more tags. Tags answer "what context does this belong to?" and are orthogonal to page type.

**Closed vocabulary.** The tag set is fixed at the schema level. A new tag is a schema upgrade discussion, not a silent addition. Candidates accumulate as notes in `log.md` until five or more pages would benefit.

| Tag | Scope |
|---|---|
| `work` | The current employer's context: people, projects, product surfaces, decisions. Rename to the employer's name on first schema upgrade if you prefer (`ebay`, `acme`). |
| `pm` | Product management craft: frameworks, decision patterns, transferable skill. |
| `career` | Your own career history and positioning as durable substrate. Distinct from `work` (current context) and `pm` (craft). |
| `content` | Opt-in. Only when a page is a genuine content seed (a post, an essay, an observation worth publishing). If you have to argue for it, it is not content. |
| `personal` | Life, health, philosophy, anything outside the categories above. |
| `ai-os` | The AI operating system itself: skills, hooks, workspaces, tool choices. |
| `archie-meta` | Archie reflecting on Archie: schema, build sessions, the wiki pattern. |

Discipline: tag at create time; multi-tag freely when honest; querying by tag is `grep -rE "tags:.*\bpm\b" wiki/`.

## Operations

### Ingest
When a file lands in `raw/` or the human says "ingest this":

1. Classify the source (one of the 8 codes).
2. Read the source. For non-text sources, run the extraction tool from `PREPROCESSORS.md` first.
3. **Discuss before compiling.** Surface key takeaways and framing to the human before writing.
4. Identify entities and concepts touched.
5. Check `entities.json` for canonical names; update aliases when new spellings appear.
6. Check `index.md` for existing pages.
7. Create the source page.
8. Update or create the concept and entity pages this source informs. **One source typically touches several pages.** If it touched only one, the ingest is incomplete.
9. Add cross-references.
10. Update `index.md` (sorted by type, then alphabetical) and its counts.
11. Append to `log.md`: `## [YYYY-MM-DD] ingest | [source title] | touched N pages`.
12. **Post-ingest audit.** Verify the touched pages were actually updated.

### Query
1. Read `index.md` to find relevant pages.
2. Read those pages; follow links.
3. Synthesize with citations to specific pages.
4. If the answer is valuable and novel, file it (new page or `outputs/`).
5. If the question reveals a gap, say so and suggest what would fill it.

### Audit
Every two to four weeks, or on request: contradictions, stale claims (older than 90 days), orphans (no inbound links), missing concept pages, detail decay, entity duplicates, suggested gaps. Output findings with severity; the human decides.

## Index Format

`index.md` is the catalog. One table per type, sorted alphabetically, with a Counts section the engine's `check.sh` verifies against disk:

```markdown
## Source
| Page | Source type | One-line summary | Tags | Last updated |
|---|---|---|---|---|
| [slug](wiki/source/slug.md) | ARTICLE | ... | pm | YYYY-MM-DD |

## Counts
- Source: N
- Concept: N
- Entity: N
- Idea: N
- Project: N
- **Total: N**
```

Read it first on every query. Update on every ingest. `scripts/render-index.py` in the engine can regenerate it from page frontmatter when counts drift.

## Principles

1. Receptive vs productive: a page is one or the other.
2. Compile, don't copy: wiki pages synthesize, they are not summaries of single documents.
3. Cross-reference aggressively: orphans are a defect.
4. Preserve direct quotes: key claims trace to a source quote.
5. The index is the map: always update it.
6. Log everything.
7. The human curates direction; the agent does the grunt work.
8. No hallucinated sources.
9. Entity canonicalization before any new entity page.
10. Mode-agnostic: operational state stays in `SESSION.md` or the workspace.

## Scope and boundaries

This brain belongs to the machine it runs on. **Nothing in `wiki/` or `raw/` leaves this machine.** The engine (skills, hooks, this schema) is shared and public; the content is not. If a lesson learned here is generalizable and yours to keep, write it down somewhere that is yours, in your own words, without the names and numbers that made it confidential.

## Self-Reference

Schema upgrades are discussions first. Each one leaves two artifacts: this file, rewritten, and a wiki page capturing the reasoning. The brain learns about its own growth.

## Scaling Notes

- `index.md` as the map works to a few hundred pages. Beyond that, add search (BM25 plus a light semantic layer plus entity matching).
- For the first ~20 ingests, review each one. Then consider a triage skill for batched inbox items.
- Page-type boundaries will pressure-test under real ingests. Re-splitting is expected, not a failure.
