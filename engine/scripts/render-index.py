#!/usr/bin/env python3
"""Regenerate knowledge/index.md from wiki page frontmatter. Deterministic.

Usage: render-index.py <knowledge_dir> [--note "Most Recent Ingest text"] [--dry-run]

Reads every wiki/<type>/*.md, parses the frontmatter (simple key: value and
key: [a, b] lines; no YAML library required), and writes index.md with one
table per type, a Counts section that skills/orient/check.sh and audit.sh verify
against disk, and a Most Recent Ingest line. Pages without a parsable
frontmatter are listed with a "(no frontmatter)" summary so nothing is hidden.
"""
import os
import re
import sys

TYPES = ["source", "concept", "entity", "idea", "project"]
HEAD = """# Archie — Index

> Catalog of all wiki pages. Sorted by type, then alphabetical within type. Read first on every query. Update on every ingest.
>
> Schema: see [SCHEMA.md](SCHEMA.md). Operations log: see [log.md](log.md). Entity canonicalization: see [entities.json](entities.json). Preprocessor mapping: see [PREPROCESSORS.md](PREPROCESSORS.md).

---
"""


def parse_frontmatter(text):
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    fm = {}
    for line in text[3:end].splitlines():
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        if val.startswith("[") and val.endswith("]"):
            val = ", ".join(v.strip().strip("'\"") for v in val[1:-1].split(",") if v.strip())
        else:
            val = val.strip("'\"")
        fm[key] = val
    return fm


def tldr(text):
    m = re.search(r"^## TLDR\s*\n+(.+)$", text, re.M)
    return m.group(1).strip() if m else ""


def clean(s, limit=160):
    s = re.sub(r"\s+", " ", s or "").replace("|", "/").strip()
    return s if len(s) <= limit else s[: limit - 1].rstrip() + "…"


def row(slug, rel, fm, text, t):
    title = fm.get("title") or fm.get("name") or slug
    date = fm.get("last_updated") or fm.get("date_added") or fm.get("last_touched") or ""
    tags = fm.get("tags", "")
    if t == "source":
        summary = tldr(text) or title
        return f"| [{slug}]({rel}) | {fm.get('source_type', '')} | {clean(summary)} | {tags} | {date} |"
    if t == "entity":
        return f"| [{slug}]({rel}) | {fm.get('entity_type', '')} | {clean(title)} | {tags} | {date} |"
    if t in ("idea", "project"):
        return f"| [{slug}]({rel}) | {fm.get('status', '')} | {clean(title)} | {tags} | {date} |"
    return f"| [{slug}]({rel}) | {clean(title)} | {tags} | {date} |"


HEADERS = {
    "source": "| Page | Source type | One-line summary | Tags | Last updated |\n|---|---|---|---|---|",
    "concept": "| Page | One-line summary | Tags | Last updated |\n|---|---|---|---|",
    "entity": "| Page | Entity type | One-line summary | Tags | Last updated |\n|---|---|---|---|---|",
    "idea": "| Page | Status | One-line summary | Tags | Last updated |\n|---|---|---|---|---|",
    "project": "| Page | Status | One-line summary | Tags | Last updated |\n|---|---|---|---|---|",
}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    kn = os.path.abspath(sys.argv[1])
    note = ""
    dry = "--dry-run" in sys.argv
    if "--note" in sys.argv:
        note = sys.argv[sys.argv.index("--note") + 1]
    out = [HEAD]
    counts = {}
    for t in TYPES:
        d = os.path.join(kn, "wiki", t)
        files = sorted(f for f in os.listdir(d) if f.endswith(".md")) if os.path.isdir(d) else []
        counts[t] = len(files)
        out.append(f"\n## {t.capitalize()}\n\n{HEADERS[t]}")
        for f in files:
            slug = f[:-3]
            rel = f"wiki/{t}/{f}"
            with open(os.path.join(d, f), encoding="utf-8", errors="replace") as fh:
                text = fh.read()
            fm = parse_frontmatter(text)
            if not fm:
                fm = {"title": f"{slug} (no frontmatter)"}
            out.append(row(slug, rel, fm, text, t))
    total = sum(counts.values())
    out.append("\n---\n\n## Counts\n")
    for t in TYPES:
        out.append(f"- {t.capitalize()}: {counts[t]}")
    out.append(f"- **Total: {total}**")
    out.append("\n## Most Recent Ingest\n")
    out.append(note or "(none yet)")
    out.append("")
    result = "\n".join(out)
    target = os.path.join(kn, "index.md")
    if dry:
        print(result)
    else:
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(result)
        print(f"index.md rendered: {total} pages ({', '.join(f'{t}={counts[t]}' for t in TYPES)})")


if __name__ == "__main__":
    main()
