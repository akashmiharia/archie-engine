#!/usr/bin/env python3
"""Merge hook entries into a Claude Code settings.json without clobbering anything.

Usage: merge-hooks.py <settings.json> <hooks-template.json> [--dry-run]

- Creates settings.json if absent.
- Preserves every existing key (permissions, env, MCP, anything).
- For each event/matcher group in the template, adds it only if no existing group
  with the same matcher already contains the same command (idempotent).
- Prints one line per action. Exit 0 always unless the files are unreadable.
"""
import json
import os
import sys


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    settings_path, template_path = sys.argv[1], sys.argv[2]
    dry = "--dry-run" in sys.argv
    with open(template_path) as fh:
        template = json.load(fh)
    settings = {}
    if os.path.exists(settings_path):
        with open(settings_path) as fh:
            raw = fh.read().strip()
        if raw:
            try:
                settings = json.loads(raw)
            except json.JSONDecodeError as e:
                print(f"ERROR {settings_path} is not valid JSON ({e}); not touching it")
                sys.exit(1)
    hooks = settings.setdefault("hooks", {})
    added = 0
    for event, groups in template.get("hooks", {}).items():
        existing = hooks.setdefault(event, [])
        for group in groups:
            matcher = group.get("matcher", "")
            cmds = {h.get("command") for h in group.get("hooks", [])}
            dup = False
            for g in existing:
                if g.get("matcher", "") == matcher:
                    have = {h.get("command") for h in g.get("hooks", [])}
                    if cmds & have:
                        dup = True
                        break
            if dup:
                print(f"keep   {event}[{matcher}] already wired")
            else:
                existing.append(group)
                added += 1
                print(f"add    {event}[{matcher}] -> {', '.join(sorted(c for c in cmds if c))}")
    if dry:
        print(json.dumps(settings, indent=2))
        return
    if added:
        tmp = settings_path + ".tmp"
        with open(tmp, "w") as fh:
            json.dump(settings, fh, indent=2)
            fh.write("\n")
        os.replace(tmp, settings_path)
        print(f"wrote  {settings_path} (+{added} hook groups)")
    else:
        print(f"ok     {settings_path} unchanged")


if __name__ == "__main__":
    main()
