# Akokuntaro Coding Skills

**Akokuntaro Coding Skills** — personal [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills)
that teach Claude David's coding conventions — preferred stacks, patterns, naming, and the
do/don't rules — so every session follows the same style.

## Skills

| Skill | When Claude uses it |
| --- | --- |
| **coding-principles** | Every coding task — reuse/DRY bias, naming, TypeScript rigor, minimal comments, error handling, do/don't. The base layer. |
| **ui-review** | Every frontend/UI task, before calling it done — the phone-compact rules (secondary elements shrink to captions, prose hidden on phones, only tables scroll), one-control-per-job pruning, optical equality, and the finishing checklist. |
| **nextjs-dashboard** | New frontends / full-stack dashboards — Next.js 15 App Router, React 19, Tailwind v4, shadcn/ui, TanStack Query, next-auth. *Default frontend.* |
| **express-prisma-api** | Standalone backend APIs — Express + TypeScript + Prisma/MySQL, layered controllers/services, `ApiError`/`ERROR_CODES`, Joi, JWT. *Default backend.* |
| **react-vite-app** | SPA frontends talking to a separate API — Vite + React 18, react-router, `globalFetch`/`assertApiOk`, react-hook-form + zod, sonner. |
| **python-app** | Python data/analytics apps — Streamlit, pandas/plotly, layered `app/` (ui/engine/db/connectors), theme module, pytest. |

`coding-principles` is the foundation; the stack skills layer on top and win on stack
specifics. Claude auto-loads the relevant skill from each `description`.

## Defaults at a glance

- **New frontend** → Next.js 15 (App Router) · **New backend** → Express + TS + Prisma
- **Styling** → Tailwind v4 + shadcn/ui · **Server state** → TanStack Query · **Client state** → React Context
- **Package manager** → npm · **Auth** → next-auth (Next) / JWT+passport (Express)
- **Reuse** → aggressive DRY · **Comments** → minimal · **TS** → strict, pragmatic on unused · **Tests** → write alongside features

## Install

One line. Finds every agent. Installs for each.

```bash
# macOS / Linux / WSL / Git Bash
curl -fsSL https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.sh | bash
```

```powershell
# Windows (PowerShell 5.1+)
irm https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.ps1 | iex
```

The installer fetches (or updates) the skills source, detects every agent that uses the
`SKILL.md` format — currently Claude Code (`~/.claude/skills`, honoring
`CLAUDE_CONFIG_DIR`) — and **symlinks** each skill into it (copying where symlinks aren't
allowed). It's re-runnable and idempotent; run it again to update.

**Env overrides**

| Var | Default | Purpose |
| --- | --- | --- |
| `SKILLS_BRANCH` | `develop` | Branch to pull |
| `SKILLS_SRC_DIR` | `~/.local/share/coding-style-skills` (`%LOCALAPPDATA%\coding-style-skills` on Windows) | Where the source lives |
| `SKILLS_TARGETS` | _(auto-detect)_ | `:`-separated (`;` on Windows) skills dirs to install into |

> The one-liners point at `develop` because that's this repo's branch. If you later make
> `main` the default branch, switch the URLs to `/main/`.

### Manual install (no script)

```bash
mkdir -p ~/.claude/skills
for s in coding-principles nextjs-dashboard express-prisma-api react-vite-app python-app; do
  ln -sfn "$(pwd)/skills/$s" ~/.claude/skills/$s
done
```

Verify with `/skills` (or list them) inside Claude Code; each should appear by name.

## Editing

Each skill is `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) plus a
markdown body. The `description` controls when Claude auto-loads the skill — keep it
specific about triggers. After editing, changes apply on the next session (no rebuild).

## Layout

```
install.sh             one-line installer (macOS / Linux / WSL / Git Bash)
install.ps1            one-line installer (Windows PowerShell)
skills/
  coding-principles/SKILL.md
  nextjs-dashboard/SKILL.md
  express-prisma-api/SKILL.md
  react-vite-app/SKILL.md
  python-app/SKILL.md
```
