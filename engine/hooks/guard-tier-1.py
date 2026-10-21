#!/usr/bin/env python3
"""
Tier 1 file-write guard — Claude Code PreToolUse hook.

Reads ~/.claude/hooks/protected-paths.conf and intercepts Edit/Write/MultiEdit/NotebookEdit
tool calls that target a Tier 1 path. Returns an `ask` permission decision via JSON to
stdout — Claude Code shows the user an inline allow/deny prompt for that single tool call.

Per-instance approval. No session-wide override needed for normal operation.

Override (rare, for batch authorization in a long session):
    export CLAUDE_TIER_1_OVERRIDE=1

Recommended pattern per Anthropic docs: https://code.claude.com/docs/en/permissions
("Start with Ask mode, identify safe patterns, then progressively allow them.")
"""
import json
import sys
import os
import fnmatch


def main():
    # Read tool input from stdin
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # If we can't parse the input, don't block — fail-open is safer than fail-closed here.
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    if tool_name not in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        sys.exit(0)

    tool_input = payload.get("tool_input", {})
    file_path = tool_input.get("file_path") or tool_input.get("notebook_path", "")
    if not file_path:
        sys.exit(0)

    # Explicit override for one session (batch authorization, rare)
    if os.environ.get("CLAUDE_TIER_1_OVERRIDE") == "1":
        sys.exit(0)

    # Load protected-paths config
    config_path = os.path.join(os.path.expanduser(os.environ.get("CLAUDE_CONFIG_DIR", "~/.claude")), "hooks", "protected-paths.conf")
    if not os.path.exists(config_path):
        sys.exit(0)

    with open(config_path) as f:
        lines = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]

    # Resolve target file path to absolute
    target = os.path.abspath(os.path.expanduser(file_path))

    matched = None
    for pattern in lines:
        if pattern.startswith("!"):
            # Exception (allow-list override). If the path matches an exception, allow immediately.
            exception_pattern = os.path.expanduser(pattern[1:])
            if fnmatch.fnmatch(target, exception_pattern):
                sys.exit(0)
        else:
            expanded_pattern = os.path.expanduser(pattern)
            if fnmatch.fnmatch(target, expanded_pattern):
                matched = pattern
                break

    if matched:
        # Return "ask" decision via JSON. Claude Code shows the user an inline allow/deny
        # prompt for THIS single tool call. Per-instance approval — granular control,
        # no session-wide state.
        decision = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": (
                    f"Tier 1 file: '{file_path}' matches protected-paths pattern '{matched}'. "
                    f"This is a top-tier file (identity / memory / architecture / hooks). "
                    f"Approve this single write, or deny. "
                    f"Config: ~/.claude/hooks/protected-paths.conf"
                ),
            }
        }
        print(json.dumps(decision))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
