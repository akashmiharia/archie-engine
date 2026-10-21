---
name: archie-mine
description: Use when Akash asks for insight from his corpus — "mine archie", "/archie-mine <question>", "what patterns do you see", "find important/interesting things in my notes", "what am I not seeing", "run an insight sweep" — or after any major ingest wave completes. Insight extraction with eval-grade evidence gates, NOT retrieval — full-slice reads (never search-hit synthesis), every claim requires 2+ dated citations grep-verified against the corpus (hallucinated quotes die mechanically), a mandatory adversarial pass (stated values vs logged behavior), and a falsifiability test that kills validation-dressed-as-discovery. Read-only: findings go to outputs/, promotion to wiki happens via /archie-ingest.
---

# Archie Mine — Insight With Evidence Gates

A query with an eval harness bolted onto the answers. Retrieval finds what you asked for; mining finds what you couldn't ask for — and then has to *prove it* from the corpus before you see it.

**Why this design (research-verified 2026-08-07):** RAG-style synthesis over personal archives is consistently shallow (retrieval returns chunks already adjacent in meaning, so it structurally cannot see a pattern spanning years); full-context reads with citation enforcement is what worked for every credible practitioner. The two anti-horoscope mechanics with independent attestation: a two-dated-citations gate with a kill-switch, and an agent whose only job is contradiction-hunting. The trap to design against: the personal-validation effect — flattering findings feel true.

## Modes

- **Directed:** `/archie-mine <question>` — mine the corpus against one question.
- **Open sweep:** no args — cross-corpus pattern hunt (default after a major ingest).
- **Adversarial-only:** `/archie-mine adversarial` — just the values-vs-behavior pass.

## Procedure

### 1. Route to slices, then read them WHOLE

Read `index.md`, pick 3–8 slices relevant to the question (or, for open sweeps, deliberately *distant* slice pairs — insight lives across domains). A slice = whole wiki pages and/or whole raw files, never snippets or grep hits. For big slices, fan out fork subagents; each fork returns candidate findings **with verbatim quotes + file paths + dates** — raw material, not conclusions.

### 2. Evidence gate (deterministic — this is the eval)

For every candidate claim:
- **Grep-verify each quote** against the cited file. Quote not found verbatim → the citation is dead. This kills hallucinated evidence mechanically, not by judgment.
- **Two-source rule:** a claim needs ≥2 dated citations from ≥2 different files (or 2 dated entries within one longitudinal file). One citation → downgrade to LEAD, never a finding.
- Undated notes cite as "(undated, raw/<file>)" — allowed, but a claim resting *only* on undated material is a LEAD.

### 3. Falsifiability gate (the anti-horoscope test)

For each surviving claim ask: *would Akash have said this himself, unprompted?* If yes → cut it, or invert it until it says something he wouldn't have. Every finding must end with **"What would falsify this:"** — one line naming the evidence that would kill it. A finding that nothing could falsify is a horoscope; delete it.

### 4. Adversarial pass (mandatory in open sweeps)

Compare **stated values** (AGENTS.md, identity pages, published essays) against **logged behavior** (dated session sources, log.md, raw notes). Report divergences neutrally, with citations on both sides. Sycophancy ban: if a sweep produces only flattering findings, the sweep failed — rerun the adversarial pass harder or report "no divergences survived the gates" explicitly.

### 5. Report

Write to `outputs/mine-YYYY-MM-DD[-slug].md`, ≤1 page:
- **Max 6 findings**, ranked by surprise × consequence. Each: claim → evidence (2+ dated cites) → so-what → falsifier.
- **LEADS** section: under-evidenced threads worth a future directed mine.
- Provenance flags where evidence is AI-mirror content vs Akash's own voice.

Present the findings conversationally to Akash; the file is the durable record.

## Hard rules

- ❌ Read-only on the brain: never writes to wiki/, memory, or registries. Promotion of a finding = `/archie-ingest` or `/session-ingest`, deliberately.
- ❌ No web research mid-mine; the corpus is the universe.
- ❌ No advice injection — findings state what IS (with evidence), not what Akash should do, except a one-line so-what.
- ❌ No unverifiable praise. The validation trap is the failure mode this skill exists to beat.
- ✅ Quotes verbatim, always dated where dates exist, provenance-honest.

## Cadence

On demand; open sweep after every major ingest wave; full adversarial sweep quarterly. Pairs with `/archie-audit` (planned) — audit runs hygiene evals on the brain's *structure*, mine runs insight evals on its *content*.

## Companions

`/archie-query` (retrieval) · `/archie-ingest` (write) · `/session-ingest` (session capture) · `/orient` (state)
