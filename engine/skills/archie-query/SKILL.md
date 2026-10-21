---
name: archie-query
description: Use whenever Akash asks a question whose answer likely lives in Archie, his personal wiki at ~/.claude/knowledge/. Triggers on questions about people in his life (anyone in entities.json), his work (current employer, product surfaces, strategy), his content engine (Product Rookies, LinkedIn, humanomics), his AI OS architecture (Archie, SCHEMA, modes), his frameworks and concepts (anything in wiki/concept/), his career arc, his mentors, or his projects and ideas (anything in wiki/project/ or wiki/idea/). Also triggers on phrases like "what's our thinking on X", "what did we decide about X", "what does Archie have on X", "lookup X", "remind me about X". Brain-first lookup — reads index.md first, then 1-5 relevant pages, synthesizes with file-path citations. Saves multi-page syntheses to outputs/. Never drifts to web search.
---

# Archie Query — brain-first lookup

The skill that flips Archie from "wiki I built" to "brain I ask." Aggressively cheap: read existing pages, cite them, don't re-derive. If Archie doesn't have the answer, say so honestly. Don't fabricate, don't drift to web.

## Steps (in order)

### 1. Read the catalog

Read `~/.claude/knowledge/index.md` first. Always. It's the table of contents. Scan the source / concept / entity / idea / project tables for candidate pages by topic, tag, or one-line summary.

If the question names a person, company, or specific term, also read `~/.claude/knowledge/entities.json` to resolve canonical names (e.g., "Peter" → person-peter-trinh, "Adobe" → company-adobe).

### 2. Identify candidate pages

Pick 1-5 most-relevant pages. Bias toward fewer reads, not more. If 2 pages cover the answer, don't read 5. The index's one-line summaries are designed for this triage; trust them.

If the question is genuinely cross-cutting (e.g., "what's our full state on the AI OS architecture?") and needs broader coverage, it's fine to read more. Justify each read briefly so the user sees the routing.

### 3. Read and synthesize

Read the candidate pages. Synthesize the answer with **inline citations** in the form `(wiki/concept/foo.md)` next to each claim. Prefer direct quotes over paraphrase when the source has memorable phrasing. Archie's voice (Akash's voice, plus the voices of people in his wiki) is the point.

If the wiki has the answer: cite specifically. If the wiki has *part* of the answer: synthesize the part you have, name the gap, don't fill the gap with guesses.

### 4. Optionally save to outputs/

Save the answer to `~/.claude/knowledge/outputs/query-YYYY-MM-DD-{slug}.md` if any of:
- The answer synthesized across 2+ pages
- Akash explicitly asks to save it
- The answer is briefing-shaped (would be useful re-reading later, not a one-time lookup)

Create `outputs/` with `mkdir -p` if it doesn't exist yet (first save).

Don't save trivial single-page lookups. The outputs folder is for compounded synthesis, not lookup receipts.

## Output format

Direct answer first. This is what Akash reads. Citations inline. End with one of:
- `Saved to outputs/query-YYYY-MM-DD-{slug}.md` (if saved)
- `Not saved — single-page lookup` (if trivial)
- `Archie doesn't have this. Gaps: {what's missing}` (if the answer isn't in the wiki)

## Hard rules

- No web search. This is brain-first. If Archie doesn't have it, say so. Web drift defeats the purpose. (Akash will explicitly ask for web research as a separate move when he wants it.)
- No fabrication. Don't paper over gaps with plausible-sounding content. Honest "Archie doesn't have this" is more valuable than a fake answer.
- No vague citations. `(the wiki)` is not a citation. `(wiki/concept/lived-experience-over-infrastructure.md)` is.
- Read index.md every time. The catalog is cheap; flying blind is expensive.
- Quote directly when phrasing matters.
- Save valuable syntheses to outputs/. The output layer is what makes Archie feel useful in real life — nobody reads their own wiki, they read what the wiki produced.

## Why this skill exists

Per `wiki/idea/archie-usage-layer.md`: most personal wikis sit unread until they rot — the exact failure mode that killed Notion Life OS. The unlock isn't more pages, it's the loop that makes the wiki produce value. `/archie-query` is the single skill that flips disposition from "I built a wiki" to "I have a brain I can ask." Garry Tan's brain-first lookup pattern, operationalized for Akash's scale.

Companions: `/archie-ingest` (next in queue), `/archie-audit` (parked), `/archie-eval` (parked).
