# My Coding Style Skills

Personal [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills) that
teach Claude David's coding conventions — preferred stacks, patterns, naming, and the
do/don't rules — so every session follows the same style.

## Skills

| Skill | When Claude uses it |
| --- | --- |
| **coding-principles** | Every coding task — reuse/DRY bias, naming, TypeScript rigor, minimal comments, error handling, do/don't. The base layer. |
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

Claude Code discovers personal skills in `~/.claude/skills/`. Point it at this repo so the
skills stay version-controlled here.

**Option A — symlink each skill (recommended; edits here apply immediately):**

```bash
mkdir -p ~/.claude/skills
for s in coding-principles nextjs-dashboard express-prisma-api react-vite-app python-app; do
  ln -sfn "$(pwd)/skills/$s" ~/.claude/skills/$s
done
```

**Option B — clone the whole repo as the skills dir:**

```bash
git clone https://github.com/ProgrammerDATCH/ProjectMyCodingStyleSkills.git ~/.claude/skills-src
ln -sfn ~/.claude/skills-src/skills/* ~/.claude/skills/   # or symlink individually
```

Verify with `/skills` (or list them) inside Claude Code; each should appear by name.

## Editing

Each skill is `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) plus a
markdown body. The `description` controls when Claude auto-loads the skill — keep it
specific about triggers. After editing, changes apply on the next session (no rebuild).

## Layout

```
skills/
  coding-principles/SKILL.md
  nextjs-dashboard/SKILL.md
  express-prisma-api/SKILL.md
  react-vite-app/SKILL.md
  python-app/SKILL.md
```
