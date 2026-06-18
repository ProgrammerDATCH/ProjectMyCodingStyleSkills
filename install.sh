#!/usr/bin/env bash
#
# Install David's coding-style skills into every detected AI agent.
#
#   curl -fsSL https://raw.githubusercontent.com/ProgrammerDATCH/ProjectMyCodingStyleSkills/develop/install.sh | bash
#
# It fetches (or updates) the skills source, finds every agent that uses the
# SKILL.md format, and symlinks each skill into it (copying if symlinks aren't
# allowed). Re-runnable and idempotent.
#
# Env overrides:
#   SKILLS_BRANCH    branch to pull         (default: develop)
#   SKILLS_SRC_DIR   where to keep source   (default: ~/.local/share/coding-style-skills)
#   SKILLS_TARGETS   ':'-separated skills dirs to install into (skips auto-detect)
#   CLAUDE_CONFIG_DIR  honored when detecting Claude Code (may be ':'-separated)

set -euo pipefail

REPO_SLUG="ProgrammerDATCH/ProjectMyCodingStyleSkills"
BRANCH="${SKILLS_BRANCH:-develop}"
SRC_DIR="${SKILLS_SRC_DIR:-$HOME/.local/share/coding-style-skills}"
SKILLS="coding-principles nextjs-dashboard express-prisma-api react-vite-app python-app"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  +\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Locate the skills source: use the surrounding checkout if present,
#    otherwise clone (or download a tarball when git is unavailable).
resolve_source() {
  self_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
  if [ -n "$self_dir" ] && [ -d "$self_dir/skills" ]; then
    SRC_DIR="$self_dir"
    info "Using local checkout at $SRC_DIR"
  elif command -v git >/dev/null 2>&1; then
    if [ -d "$SRC_DIR/.git" ]; then
      info "Updating skills source in $SRC_DIR"
      git -C "$SRC_DIR" pull --ff-only --quiet || warn "could not update; using existing copy"
    else
      info "Cloning skills into $SRC_DIR"
      rm -rf "$SRC_DIR"
      git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO_SLUG.git" "$SRC_DIR" --quiet
    fi
  else
    command -v curl >/dev/null 2>&1 || die "need git or curl to download the skills"
    info "Downloading skills tarball into $SRC_DIR"
    rm -rf "$SRC_DIR"; mkdir -p "$SRC_DIR"
    curl -fsSL "https://github.com/$REPO_SLUG/archive/refs/heads/$BRANCH.tar.gz" \
      | tar -xz -C "$SRC_DIR" --strip-components=1
  fi
  [ -d "$SRC_DIR/skills" ] || die "skills/ not found in $SRC_DIR"
}

# 2. Find every agent that consumes SKILL.md skills. Prints "Name|/skills/dir"
#    per line. Extend the known list below as more agents are supported.
discover_agents() {
  if [ -n "${SKILLS_TARGETS:-}" ]; then
    printf '%s\n' "$SKILLS_TARGETS" | tr ':' '\n' | while IFS= read -r d; do
      [ -n "$d" ] && printf 'Custom|%s\n' "$d"
    done
    return
  fi
  # Claude Code — respects CLAUDE_CONFIG_DIR (which may itself be ':'-separated).
  printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" | tr ':' '\n' | while IFS= read -r home; do
    [ -n "$home" ] && printf 'Claude Code|%s/skills\n' "$home"
  done
}

# 3. Symlink every skill into one agent's skills dir (copy if symlinks fail).
install_into() {
  name="$1"; dir="$2"
  mkdir -p "$dir"
  for s in $SKILLS; do
    target="$SRC_DIR/skills/$s"; link="$dir/$s"
    [ -d "$target" ] || die "missing skill: $target"
    if ln -sfn "$target" "$link" 2>/dev/null; then :; else
      rm -rf "$link"; cp -R "$target" "$link"
    fi
  done
  ok "$name -> $dir"
}

main() {
  info "Installing coding-style skills"
  resolve_source

  agents="$(discover_agents)"
  if [ -z "$agents" ]; then
    warn "no agents detected — defaulting to Claude Code (~/.claude)"
    agents="Claude Code|$HOME/.claude/skills"
  fi

  printf '%s\n' "$agents" | while IFS= read -r entry; do
    [ -n "$entry" ] && install_into "${entry%%|*}" "${entry#*|}"
  done
  info "Done — installed: ${SKILLS// /, }"
  info "Start a new agent session to pick up the skills."
}

main "$@"
