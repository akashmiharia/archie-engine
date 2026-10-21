---
description: When to use CLI vs direct API vs MCP for external services, and how to verify tool/platform claims before asserting them
---

# Tool Selection — cheapest sufficient surface, verified

## The principle (2026 framing)

Reach for the **cheapest surface that's sufficient** for the task. The old "CLI beats MCP, period" rule is a special case of a deeper one that current practice (Anthropic's *code execution with MCP*, Cloudflare's *Code Mode*) has converged on:

**Agents are good at code. Prefer letting the model call APIs/CLIs from code for deterministic ops, load tool definitions on demand, and filter results before they hit context.**

Three moves, in rough order of preference:

1. **CLI / direct API from code, for a known deterministic op.** If a mature CLI exists (`gh`, `git`, `vercel`, `stripe`) or the service has a clean REST API, call it via Bash/`curl`/SDK. A typical CLI command is ~200 tokens; a naive MCP operation can be ~30k (schema upfront + intermediate results round-tripping through context). For focused single-service CRUD (a status change, a page append, a comment), that overhead is pure waste.
2. **MCP with progressive disclosure, for multi-service orchestration or no-API surfaces.** MCP earns its cost when (a) orchestrating several services in one flow, or (b) the surface has no good CLI/API. **The overhead critique is now partly solved at the harness layer** — tool-search / deferred tool loading (this very harness does it) means schemas load on demand, not all upfront. So don't reject MCP reflexively; reject *eagerly loading a fat MCP schema for a one-off*.
3. **Code execution over MCP, when results are large or multi-step.** Filter/transform in the execution environment before returning to context. Anthropic's worked example: 150k → 2k tokens (98.7%) by writing code that calls tools rather than chaining direct calls.

**Decision shortcuts:**
- Single service + predictable op + API/CLI exists → CLI or direct API.
- Several services in one flow, or no API → MCP (lazy-load what you need).
- Large/iterative result set → do it in code, log only what matters.
- Never fall back to a heavier surface silently — if the cheap path fails, say so and ask.

## Your surfaces (fill in)

<!-- One line per external service you use from the agent, with the surface you chose and why. Examples: -->
- **GitHub** → `gh` CLI (if your org allows it). Don't reach for an MCP for git/PR ops.
- **Web search / scrape** → the `firecrawl*` skills + `FIRECRAWL_API_KEY` (optional; set it on this machine or leave the skills idle).
- **Your employer's docs / wiki / tickets** → the MCP or export path your org provides. Never route internal content through a personal API key.

## Modular MCP — optimal default + documented fallback

When a service offers more than one way to connect (a hosted OAuth MCP and/or a self-hosted static-token MCP), wire the **vendor-optimal option as the default**, keep the other as a **documented one-command fallback**, and **swap only when a concrete blocker trips** (auth friction, token cost, org policy). One active at a time — modularity means both *documented* and *cheap to swap*, not both running. Full reasoning: [[modular-mcp]].

- **Notion (2026-06):** default = hosted MCP (`mcp.notion.com`, OAuth, returns Markdown = token-efficient); fallback = static-token local `@notionhq/notion-mcp-server` + `NOTION_TOKEN`. The every-session re-auth that prompted this was a cross-MCP Claude Code OAuth refresh bug (`anthropics/claude-code#28256`), partially fixed in v2.1.136 — not Notion-specific. Update Claude Code and test before assuming you need the fallback.
- Trap: a service's *hosted* MCP and *local* server are different surfaces with different auth and tool sets — check what each exposes before concluding a service "requires OAuth."

## Verify recency before recommending — or asserting the limits of — a tool/platform

This space moves fast; training knowledge goes stale within months. **When about to recommend** a tool, library, MCP-vs-CLI-vs-API choice, model, or workflow **AND** the recommendation rests on training knowledge (not something just verified) **AND** Akash hasn't already stated a preference **AND** the choice is consequential or recurring → verify against current sources *before* asserting, then surface what you found.

- **Asserting limitations is the highest-cost case — verify negatives.** Before stating a platform/tool *can't* do something or that a bug is *unfixed* ("not possible", "unsupported", "no API/endpoint", "deprecated", "requires version X"), verify in-turn or label `[unverified]`. Negatives kill options and cause wasted work. The "REST beats MCP" framing above was itself stale until checked — exactly the failure mode this guards against.
- **Cheap verification on hand:** `context7` (live library/framework docs), the `claude-code-guide` agent (Claude / Anthropic / Agent-SDK / API), `firecrawl` (community + current practice). One targeted call, not a research expedition.
- **Don't verify** trivial/reversible choices, stable well-known answers, or anything Akash has already decided.
- Mirrored at the memory layer: [[verify-platform-claims]] (two-front pairing — rule + memory, same trigger).
