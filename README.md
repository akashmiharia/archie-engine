# archie-engine

A portable operating system for working with AI agents. Install it on any machine in ten minutes and Claude Code, Codex, and Cursor already know how you work, backed by a plain-text knowledge base that compounds from day one.

Built and used daily by [Akash Miharia](https://www.linkedin.com/in/akashmiharia). MIT licensed. Bring your own profile.

## The idea in one paragraph

Every AI tool forgets you when the chat ends, so every morning you re-explain who you are, what you're working on, and how you like things written. This engine replaces that with a folder of text files the tools read first. When you learn something, it goes back in the folder. The machinery is public; what you put in it is yours and stays on your machine.

## Four layers

| Layer | What it is | Shared? | Where |
|---|---|---|---|
| **Engine** | skills, hooks, schema, audit script, installer | public (this repo) | `~/.claude/{skills,hooks,rules}` + `knowledge/{SCHEMA,audit.sh,PREPROCESSORS}` |
| **Persona** | one file on how to work with you: voice, working style, what to design around | yours, private | `~/.claude/AGENTS.md` (also linked into Codex and your workspace for Cursor) |
| **Craft** | what you know that transfers between jobs: frameworks, exemplars, lessons | yours, private, reviewed page by page | arrives as pages in the brain, marked `craft_seed:` |
| **Brain** | everything you learn on this machine | this machine only | `~/.claude/knowledge/` (local git, no remote) |

Data flows one way: from your personal brain into a new machine's brain through a reviewed pack. Nothing flows back.

## Install (macOS / Linux)

```bash
unzip archie-portable-*.zip && cd archie-portable-*
bash install.sh --profile <name> --workspace ~/workspace
```

With the public repo instead of a bundle:

```bash
git clone https://github.com/akashmiharia/archie-engine.git
cd archie-engine
cp -R profiles/_template profiles/me   # fill in profiles/me/AGENTS.md
bash install.sh --profile me --workspace ~/workspace
```

What the installer does, in order, printing every action: lays down engine files; writes `engine.conf` and the Tier-1 protected-paths list for this machine; merges three hook entries into `~/.claude/settings.json` without touching anything else; creates the brain from the template (or keeps an existing one); applies craft pages and renders `index.md`; symlinks the persona into `~/.codex/AGENTS.md` and `<workspace>/AGENTS.md`; initialises the brain as a local git repo with a credentials pre-commit check; runs the orient check and the audit. Anything it would replace is backed up to `~/.claude/_backup-<timestamp>/`. Re-running is safe. Honours `CLAUDE_CONFIG_DIR` and `CODEX_HOME`.

Flags: `--no-craft`, `--pack <zip>` (apply a craft pack to an existing install), `--skills-as-project` (if enterprise policy locks personal skills), `--force`, `--dry-run`.

## Ten minutes after install

1. Open Claude Code from your home directory. The first reply opens with an orient brief (the hook ran). If it didn't, type `/orient`.
2. Paste `profiles/<name>/custom-instructions.md` into ChatGPT → Personalization and Cursor → User Rules.
3. Open Cursor or Codex on your workspace. The `AGENTS.md` there is your persona.
4. Write the first page of the brain yourself: `knowledge/wiki/project/<what-you-own>.md`. Then `/archie-ingest` your onboarding doc. One ingest a day beats a batch a month.

## The skills

`/orient` (session brief, drift check) · `/archie-query` (ask the brain) · `/archie-ingest` (add a source) · `/archie-mine` (bulk corpora) · `/session-ingest` (capture a session's learnings) · `/living-doc` (keep a document current) · plus the superpowers set for planning and execution (`brainstorming`, `writing-plans`, `executing-plans`, `systematic-debugging`, `verification-before-completion`) and `firecrawl*` for web extraction (needs `FIRECRAWL_API_KEY`, set it or ignore them).

## What is deliberately not here

- `settings.json`, credentials, MCP configs: machine-specific, never in a repo.
- Memory files and the `projects/` tree: per machine.
- Any brain content. The allowlist `.gitignore` in the source repo makes this structural, not a promise.
- Anyone's persona or craft. The template is the only profile shipped publicly.

## Enterprise-managed machines

Managed Claude Code settings can disable hooks (`disableAllHooks`, `allowManagedHooksOnly`) or lock skills to plugin sources. The installer reads the managed-settings file if present and warns. Everything still works, just less automatically: run `/orient` yourself, and the Tier-1 guard becomes the rule text in `CLAUDE.md`. If skills are locked, re-run with `--skills-as-project`.

## Updating

Engine: `git pull` in the clone (or unzip a newer bundle) and re-run `install.sh`; it only changes what differs and backs up what it replaces. Persona and craft: a new bundle or `--pack <craft-pack.zip>`.

## Credits

Patterns from Andrej Karpathy's LLM wiki gist, Aakash Gupta's PM second brain, and Garry Tan's gbrain. The superpowers skills are by Jesse Vincent (obra). Hardened over six months on the author's own brain.

Windows is not supported (bash, symlinks). WSL works.
