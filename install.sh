#!/bin/bash
# archie-engine installer. Lays down the engine + a profile + (optionally) a craft seed
# on a fresh machine, or applies a craft pack to an existing install.
#
#   bash install.sh [--profile NAME] [--workspace DIR] [--no-craft] [--pack ZIP]
#                   [--skills-as-project] [--force] [--dry-run]
#
# Idempotent: re-running changes nothing that is already in place. Anything it would
# replace is backed up first to <config>/_backup-<timestamp>/. Never overwrites an
# existing file without --force. Honors CLAUDE_CONFIG_DIR and CODEX_HOME.
# macOS / Linux only (bash + symlinks). Requires git and python3.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE=""; WORKSPACE="$HOME/workspace"; CRAFT=1; PACK=""; SKILLS_AS_PROJECT=0; FORCE=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2;;
    --workspace) WORKSPACE="$2"; shift 2;;
    --no-craft) CRAFT=0; shift;;
    --pack) PACK="$2"; shift 2;;
    --skills-as-project) SKILLS_AS_PROJECT=1; shift;;
    --force) FORCE=1; shift;;
    --dry-run) DRY=1; shift;;
    -h|--help) sed -n '2,12p' "$0"; exit 0;;
    *) echo "unknown flag: $1"; exit 2;;
  esac
done
CD="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX="${CODEX_HOME:-$HOME/.codex}"
KN="$CD/knowledge"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CD/_backup-$TS"
ENGINE="$HERE/engine"
say()  { echo "  $*"; }
act()  { if [ $DRY -eq 1 ]; then echo "  [dry] $*"; else echo "  $*"; fi; }
die()  { echo "STOP: $*"; exit 1; }
run()  { [ $DRY -eq 1 ] || "$@"; }

echo "archie-engine install"
echo "  config dir : $CD"
echo "  codex dir  : $CODEX"
echo "  workspace  : $WORKSPACE"

# --- 0. Prerequisites and policy ---
command -v git >/dev/null || die "git not found. On macOS run: xcode-select --install"
command -v python3 >/dev/null || die "python3 not found. On macOS run: xcode-select --install"
MANAGED="/Library/Application Support/ClaudeCode/managed-settings.json"
if [ -f "$MANAGED" ]; then
  python3 -I - "$MANAGED" <<'EOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"  WARN managed settings present but unreadable: {e}"); sys.exit(0)
if d.get("disableAllHooks"): print("  WARN managed policy sets disableAllHooks: the orient hook and the Tier-1 guard will not run. /orient still works on demand.")
if d.get("allowManagedHooksOnly"): print("  WARN managed policy sets allowManagedHooksOnly: user hooks are blocked. /orient still works on demand.")
s = d.get("strictPluginOnlyCustomization", {})
if isinstance(s, dict) and s.get("skills"): print("  WARN managed policy locks skills to plugin sources. Re-run with --skills-as-project, or ask your admin.")
if d.get("disableSkillShellExecution"): print("  WARN managed policy disables shell execution inside skills; check.sh may not run from /orient.")
print("  managed settings found; see any WARN lines above")
EOF
fi

# --- profile resolution ---
if [ -z "$PROFILE" ]; then
  if [ -d "$HERE/profiles/rookie" ]; then PROFILE=rookie; else PROFILE=_template; fi
fi
PDIR="$HERE/profiles/$PROFILE"
[ -d "$PDIR" ] || die "profile not found: $PDIR"
[ -f "$PDIR/AGENTS.md" ] || die "profile has no AGENTS.md: $PDIR"
echo "  profile    : $PROFILE"

backup_if_differs() { # $1=target $2=source
  if [ -e "$1" ] && ! cmp -s "$1" "$2"; then
    run mkdir -p "$BACKUP/$(dirname "${1#$CD/}")"
    run cp -p "$1" "$BACKUP/${1#$CD/}" 2>/dev/null || run cp -p "$1" "$BACKUP/$(basename "$1")"
    return 0
  fi
  return 1
}
place_file() { # $1=source $2=target ; respects --force
  if [ -e "$2" ] && cmp -s "$1" "$2"; then say "same   ${2#$HOME/}"; return; fi
  if [ -e "$2" ] && [ $FORCE -eq 0 ]; then say "keep   ${2#$HOME/} (exists; --force to replace)"; return; fi
  backup_if_differs "$2" "$1" && say "backup ${2#$HOME/} -> ${BACKUP#$HOME/}"
  run mkdir -p "$(dirname "$2")"
  run cp -p "$1" "$2"; act "write  ${2#$HOME/}"
}
place_tree() { # $1=source dir $2=target dir (file-by-file, so existing extras survive)
  (cd "$1" && find . -type f ! -name .DS_Store) | sed 's|^\./||' | while read -r rel; do
    place_file "$1/$rel" "$2/$rel"
  done
}

# --- 1. Engine files ---
echo "[1/8] engine"
run mkdir -p "$CD"
place_file "$PDIR/AGENTS.md" "$CD/AGENTS.md"
if [ -f "$PDIR/CLAUDE.md" ]; then place_file "$PDIR/CLAUDE.md" "$CD/CLAUDE.md"; else place_file "$ENGINE/CLAUDE.md" "$CD/CLAUDE.md"; fi
place_tree "$ENGINE/rules" "$CD/rules"
if [ $SKILLS_AS_PROJECT -eq 1 ]; then
  place_tree "$ENGINE/skills" "$WORKSPACE/.claude/skills"
else
  place_tree "$ENGINE/skills" "$CD/skills"
fi
run chmod +x "$CD/skills/orient/check.sh" 2>/dev/null
place_file "$ENGINE/hooks/guard-tier-1.py" "$CD/hooks/guard-tier-1.py"
place_file "$ENGINE/hooks/session-orient.sh" "$CD/hooks/session-orient.sh"
run mkdir -p "$CD/scripts"
for s in render-index.py merge-hooks.py leak-gate.sh; do place_file "$ENGINE/scripts/$s" "$CD/scripts/$s"; done

# --- 2. engine.conf + protected paths ---
echo "[2/8] machine config"
MEMDIR="$CD/projects/$(echo "$HOME" | tr '/' '-')/memory"
TMPCONF="$(mktemp)"
cat > "$TMPCONF" <<EOF
# Machine-specific paths for the engine (read by skills/orient/check.sh). Shell syntax.
# Written by install.sh on $TS. Edit freely.
MEMDIR="$MEMDIR"
WORKSPACES="$WORKSPACE"
IDENTITY_FILE=""
EOF
place_file "$TMPCONF" "$CD/engine.conf"; rm -f "$TMPCONF"
TMPPP="$(mktemp)"
sed -e "s|__CLAUDE_DIR__|$CD|g" -e "s|__MEMDIR__|$MEMDIR|g" "$ENGINE/hooks/protected-paths.conf.template" > "$TMPPP"
place_file "$TMPPP" "$CD/hooks/protected-paths.conf"; rm -f "$TMPPP"

# --- 3. Hooks into settings.json ---
echo "[3/8] hooks -> settings.json"
TMPH="$(mktemp)"
sed -e "s|__CLAUDE_DIR__|$CD|g" "$ENGINE/scripts/hooks-template.json" > "$TMPH"
if [ $DRY -eq 1 ]; then python3 -I "$ENGINE/scripts/merge-hooks.py" "$CD/settings.json" "$TMPH" --dry-run >/dev/null && say "[dry] would merge hooks"; else python3 -I "$ENGINE/scripts/merge-hooks.py" "$CD/settings.json" "$TMPH" | sed 's/^/  /'; fi
rm -f "$TMPH"

# --- 4. Brain ---
echo "[4/8] brain at $KN"
if [ -d "$KN/wiki" ]; then
  say "exists (keeping); craft pages will be added, not replaced"
else
  run mkdir -p "$KN"
  place_tree "$ENGINE/brain-template" "$KN"
  run chmod +x "$KN/audit.sh"
  run sed -i '' -e "s/Last updated: YYYY-MM-DD (what changed)/Last updated: $(date +%Y-%m-%d) (installed)/" "$KN/SESSION.md" 2>/dev/null || true
fi

# --- 5. Craft seed / pack ---
echo "[5/8] craft"
apply_pages() { # $1=pages dir
  local added=0 kept=0
  for t in source concept entity idea project; do
    [ -d "$1/$t" ] || continue
    for f in "$1/$t"/*.md; do
      [ -e "$f" ] || continue
      tgt="$KN/wiki/$t/$(basename "$f")"
      if [ -e "$tgt" ] && [ $FORCE -eq 0 ]; then kept=$((kept+1)); else run mkdir -p "$KN/wiki/$t"; run cp -p "$f" "$tgt"; added=$((added+1)); fi
    done
  done
  echo "$added added, $kept already present"
}
SEEDNOTE=""
if [ -n "$PACK" ]; then
  [ -f "$PACK" ] || die "pack not found: $PACK"
  PK="$(mktemp -d)"; unzip -q "$PACK" -d "$PK" || die "could not unzip $PACK"
  PAGES="$(find "$PK" -type d -name pages | head -1)"
  [ -n "$PAGES" ] || die "pack has no pages/ dir"
  r=$(apply_pages "$PAGES"); say "pack   $(basename "$PACK"): $r"
  [ "${r%% *}" != "0" ] && SEEDNOTE="$(date +%Y-%m-%d): applied craft pack $(basename "$PACK") ($r)"
  rm -rf "$PK"
elif [ $CRAFT -eq 1 ] && [ -d "$HERE/craft/pages" ]; then
  r=$(apply_pages "$HERE/craft/pages"); say "seed   $r"
  [ "${r%% *}" != "0" ] && SEEDNOTE="$(date +%Y-%m-%d): seeded from craft bundle $(basename "$HERE") ($r). Manifest: craft/MANIFEST.md in the bundle."
  if [ -d "$HERE/craft/pm-os" ]; then
    if [ -d "$WORKSPACE/pm-os" ]; then say "keep   pm-os already at $WORKSPACE/pm-os"; else run mkdir -p "$WORKSPACE"; run cp -R "$HERE/craft/pm-os" "$WORKSPACE/pm-os"; act "write  $WORKSPACE/pm-os"; fi
  fi
else
  say "none"
fi
if [ $DRY -eq 0 ]; then
  PREVNOTE="$(awk '/^## Most Recent Ingest/{f=1;next} f&&NF{print;exit}' "$KN/index.md" 2>/dev/null)"
  python3 -I "$CD/scripts/render-index.py" "$KN" --note "${SEEDNOTE:-${PREVNOTE:-$(date +%Y-%m-%d): installed}}" | sed 's/^/  /'
  if [ -n "$SEEDNOTE" ]; then
    printf '\n## [%s] seed | craft pages applied\n- **Action:** seed\n- **Notes:** %s\n' "$(date +%Y-%m-%d)" "$SEEDNOTE" >> "$KN/log.md"
  fi
fi

# --- 6. Codex + workspace ---
echo "[6/8] codex + workspace"
link() { # $1=target(existing file) $2=linkpath
  if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then say "same   ${2#$HOME/} -> ${1#$HOME/}"; return; fi
  if [ -e "$2" ] && [ $FORCE -eq 0 ]; then say "keep   ${2#$HOME/} exists and is not our link (--force to replace)"; return; fi
  if [ -e "$2" ] || [ -L "$2" ]; then run mkdir -p "$BACKUP"; run mv "$2" "$BACKUP/$(basename "$2").$TS"; say "backup ${2#$HOME/}"; fi
  run mkdir -p "$(dirname "$2")"; run ln -s "$1" "$2"; act "link   ${2#$HOME/} -> ${1#$HOME/}"
}
run mkdir -p "$CODEX" "$WORKSPACE"
link "$CD/AGENTS.md" "$CODEX/AGENTS.md"
link "$CD/AGENTS.md" "$WORKSPACE/AGENTS.md"

# --- 7. Brain repo + secrets pre-commit ---
echo "[7/8] brain git"
if [ $DRY -eq 0 ]; then
  if ! git -C "$KN" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$KN" init -q && say "init   $KN (local only; no remote by design)"
  fi
  cat > "$KN/.git/hooks/pre-commit" <<'EOF'
#!/bin/bash
# Refuse commits that stage credential-shaped strings. Installed by archie-engine.
CREDS='sk-[A-Za-z0-9]{20,}|fc-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY'
if git diff --cached -U0 | grep -E '^\+' | grep -qE "$CREDS"; then
  echo "pre-commit: credential-shaped string in staged changes. Remove it (keys never belong in the brain)."; exit 1
fi
EOF
  chmod +x "$KN/.git/hooks/pre-commit"
  if [ -n "$(git -C "$KN" status --porcelain)" ]; then
    git -C "$KN" add -A && git -C "$KN" -c user.name="archie-engine" -c user.email="engine@local" commit -q -m "archie: ${SEEDNOTE:-install} ($TS)" && say "commit $(git -C "$KN" rev-parse --short HEAD)"
  else
    say "clean  nothing to commit"
  fi
fi

# --- 8. Verify ---
echo "[8/8] verify"
if [ $DRY -eq 1 ]; then say "[dry] skipped"; exit 0; fi
OUT="$(CLAUDE_CONFIG_DIR="$CD" bash "$CD/skills/orient/check.sh" 2>&1)"
echo "$OUT" | sed 's/^/  /'
echo "$OUT" | grep -q '^DRIFT' && die "orient check reports DRIFT (see above)"
AUD="$(ARCHIE_KNOWLEDGE="$KN" bash "$KN/audit.sh" 2>&1)"
echo "$AUD" | grep -E '^(FAIL|SKIP|AUDIT)' | sed 's/^/  /'
echo "$AUD" | grep -q 'AUDIT: ALL PASS' || die "audit reports failures (run: bash $KN/audit.sh)"
echo
echo "DONE. Next:"
echo "  1. Open Claude Code from \$HOME  →  expect the <session-start-orient> brief on the first reply."
echo "  2. Paste profiles/$PROFILE/custom-instructions.md into ChatGPT (Personalization) and Cursor (User Rules)."
echo "  3. Open Cursor / Codex on $WORKSPACE  →  AGENTS.md there is the persona."
echo "  4. First on-prem task: write knowledge/wiki/project/<your-product>.md, then /archie-ingest your onboarding doc."
[ -d "$BACKUP" ] && echo "  (backups of replaced files: $BACKUP)"
exit 0
