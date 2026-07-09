#!/usr/bin/env bash
# Helper for the upload-session-to-proto-box skill.
#
# Resolves Claude Code session transcripts (JSONL under ~/.claude/projects/<slug>/)
# and renders one to a self-contained static HTML site via simonw's
# claude-code-transcripts tool, ready to hand to proto-box's upload_site.
#
# Usage:
#   session-tool.sh list [N]                 List N recent sessions in this project (default 10)
#   session-tool.sh render [SESSION] [OUT]   Render a session to an HTML dir; prints the dir path
#
# SESSION may be: a session id (uuid), an absolute path to a .jsonl file, or
# omitted (defaults to the current / most-recently-modified session in this project).
set -euo pipefail

PROJECTS_DIR="$HOME/.claude/projects"

# Claude Code encodes the session cwd into a project dir name by replacing every
# non-alphanumeric character with '-'. Derive that slug from the current dir.
project_dir() {
  local slug
  slug="$(printf '%s' "$PWD" | sed 's/[^a-zA-Z0-9]/-/g')"
  local dir="$PROJECTS_DIR/$slug"
  if [[ -d "$dir" ]]; then
    printf '%s\n' "$dir"
  else
    # Fallback: whichever project dir was touched most recently.
    local d newest=""
    for d in "$PROJECTS_DIR"/*/; do
      [[ -d "$d" ]] || continue
      if [[ -z "$newest" || "$d" -nt "$newest" ]]; then newest="$d"; fi
    done
    printf '%s\n' "$newest"
  fi
}

# Newest .jsonl in a dir (the live session is always the freshest).
newest_session() {
  local f newest=""
  for f in "$1"/*.jsonl; do
    [[ -e "$f" ]] || continue
    if [[ -z "$newest" || "$f" -nt "$newest" ]]; then newest="$f"; fi
  done
  printf '%s\n' "$newest"
}

# Extract the first real human prompt from a transcript, for labelling.
first_prompt() {
  python3 - "$1" <<'PY'
import sys, json
path = sys.argv[1]
def text(c):
    if isinstance(c, str): return c
    if isinstance(c, list):
        return " ".join(p.get("text","") for p in c if isinstance(p, dict) and p.get("type")=="text")
    return ""
try:
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try: o = json.loads(line)
            except Exception: continue
            if o.get("type") != "user" or o.get("isMeta") or o.get("isSidechain"): continue
            m = o.get("message") or {}
            if m.get("role") != "user": continue
            t = text(m.get("content")).strip()
            # Skip tool_result-only turns and command wrappers.
            if not t or t.startswith("<") or t.startswith("[Request interrupted"): continue
            print(" ".join(t.split())[:100]); break
except Exception:
    pass
PY
}

cmd_list() {
  local n="${1:-10}" dir
  dir="$(project_dir)"
  echo "Project transcripts: $dir"
  echo
  local files
  files="$(/bin/ls -t "$dir"/*.jsonl 2>/dev/null | head -"$n")" || true
  if [[ -z "$files" ]]; then echo "(no sessions found)"; return 0; fi
  local i=0
  while IFS= read -r f; do
    i=$((i+1))
    local id when size prompt
    id="$(basename "$f" .jsonl)"
    when="$(/bin/date -r "$f" '+%Y-%m-%d %H:%M')"
    size="$(du -h "$f" | cut -f1)"
    prompt="$(first_prompt "$f")"
    printf '%2d. %s  %6s  %s\n' "$i" "$when" "$size" "$id"
    [[ -n "$prompt" ]] && printf '    "%s"\n' "$prompt"
  done <<< "$files"
  echo
  echo "Newest (default target) is #1."
}

resolve_session() {
  local arg="${1:-}" dir
  dir="$(project_dir)"
  if [[ -z "$arg" ]]; then
    newest_session "$dir"
  elif [[ -f "$arg" ]]; then
    printf '%s\n' "$arg"
  elif [[ -f "$dir/$arg.jsonl" ]]; then
    printf '%s\n' "$dir/$arg.jsonl"
  elif [[ -f "$dir/$arg" ]]; then
    printf '%s\n' "$dir/$arg"
  else
    echo "Session not found: $arg" >&2
    return 1
  fi
}

cmd_render() {
  local session out filtered here
  session="$(resolve_session "${1:-}")"
  out="${2:-${TMPDIR:-/tmp}/cc-session-$(basename "$session" .jsonl)}"
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  rm -rf "$out"

  # Pre-filter the transcript into a clean, tool-free reading view before
  # rendering, so both the body pages and the index/counts come out tool-free.
  filtered="${TMPDIR:-/tmp}/$(basename "$session" .jsonl).filtered.jsonl"
  echo "Filtering out tool calls/results and control turns: $session" >&2
  python3 "$here/filter-transcript.py" "$session" "$filtered" >&2

  echo "Rendering: $filtered" >&2
  uvx --from claude-code-transcripts claude-code-transcripts json "$filtered" -o "$out" >&2

  # The generated index summary still carries plumbing counts
  # ("N messages · N tool calls · N commits"); reduce it to prompts + pages.
  python3 - "$out/index.html" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = re.sub(r"(\d+ prompts)(?: · [^·<]+)*( · \d+ pages)", r"\1\2", s)
open(p, "w", encoding="utf-8").write(s)
PY
  echo >&2
  echo "Site: $out" >&2
  du -sh "$out" >&2 || true
  # Stdout = just the dir path, for the caller to pass to upload_site.
  printf '%s\n' "$out"
}

case "${1:-}" in
  list)   shift; cmd_list "$@" ;;
  render) shift; cmd_render "$@" ;;
  *) echo "usage: $0 {list [N] | render [SESSION] [OUT]}" >&2; exit 2 ;;
esac
