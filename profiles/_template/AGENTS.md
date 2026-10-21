# <Your Name> — Agent Persona

> Always-on instruction layer for any agentic tool working with you (Claude Code, Codex, Cursor). This is the persona: how to work with you. Keep life facts out; the brain on this machine holds context. Fill every bracket, delete what doesn't apply, keep it under ~150 lines.
>
> *Profile version: <name> v1, <date>.*

---

## Who You're Working With

**<Your name>** — <one sentence: what you do and what you care about>.

<One line you'd put on a wall: your thesis, your lens.>

---

## How to Talk to <Name>

- <How you want prose written: sentence length, rhythm, register.>
- <Patterns to avoid. Name them concretely: tics, openers, hedges.>
- <When to use bullets vs prose.>
- <Partner or assistant? Push back or comply? Say which.>
- Before structural changes (editing this file, creating files, reorganizing directories), explain the reasoning and get confirmation.
- Don't swing to extremes when corrected. Update only what was wrong.

---

## Working Style — How <Name> Thinks

- <Primary lens: first principles, frameworks, data, taste. Be specific.>
- <What good thinking looks like to you.>
- <The lenses you use to slice an idea.>

---

## Cognitive Profile — Design Around These

- <Attention pattern and what helps.>
- <Energy pattern: the system must work on the worst day.>
- <Your failure mode and its fix.>
- <The structure you thrive in.>

---

## Operating Philosophy

- <Three to five one-liners you actually live by.>

---

## Current Context (on-prem; fill in and keep current)

- **Role line:** <title, team, location>
- **Mandate as written:** <paste it>
- **This quarter's three priorities:** 1. … 2. … 3. …
- **Manager / skip / key partners:** <names and what each one needs from you>

---

## Project Map (one row per workspace that owns its own context file)

| Mode | Folder | What it is |
|---|---|---|
| **Default** | anywhere outside mode folders | General work, the brain, writing |
| <mode> | `~/<workspace>/<name>/` | … |

**Launch discipline.** Context is layered: this global layer loads everywhere, and any dir with its own `CLAUDE.md` / `AGENTS.md` stacks a workspace layer on top.

---

## Where Things Go (routing)

| What | Where | Why |
|---|---|---|
| Universal agent rule (every session) | `~/.claude/AGENTS.md` (this file) | Always-on |
| Claude-specific behavior | `~/.claude/CLAUDE.md` | Claude harness only |
| Topic-scoped rule | `~/.claude/rules/<name>.md` | On-demand family of guidelines |
| Reusable workflow | `~/.claude/skills/<name>/SKILL.md` | Skill-triggered |
| Lasting knowledge that compounds | `~/.claude/knowledge/wiki/` | Archie |
| Open priorities | `~/.claude/knowledge/SESSION.md` | The cockpit |
| Quick observation the agent noticed | auto-memory (`~/.claude/projects/…/memory/`) | Drift fixes |
| Secrets, credentials | *never in any of the above* | Keychain / env vars |

---

## Top-Tier File Discipline

Enforced by the `guard-tier-1.py` PreToolUse hook reading `hooks/protected-paths.conf`:

- **Tier 1 (always prompts):** this file, CLAUDE.md, `rules/*.md`, `knowledge/SCHEMA.md`, memory files, the hook system.
- **Tier 2 (write when the broader task is authorized):** wiki pages, `index.md`, `log.md`, `entities.json`, `SESSION.md`.
- **Tier 3 (write freely):** workspaces, outputs.

**Machine boundary.** This brain belongs to this machine. Nothing in `knowledge/` leaves it.
