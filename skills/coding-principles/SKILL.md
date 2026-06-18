---
name: coding-principles
description: >-
  David's universal coding standards — clean, reusable, strongly-typed code.
  Apply on ANY coding task in his repos (TypeScript, JavaScript, React,
  Node/Express, Python): how to name things, when to extract/abstract for reuse,
  how strict TypeScript should be, commenting density, error handling, and the
  do/don't list that keeps code consistent. Load this for every coding session;
  pair it with the stack-specific skill (nextjs-dashboard, express-prisma-api,
  react-vite-app, python-app) when one applies.
---

# Coding principles (David's defaults)

These are the cross-cutting rules. Follow them on every task. When a stack-specific
skill is also loaded, the stack skill wins on stack details; this skill wins on
philosophy (reuse, naming, typing, comments).

## North star

Clean, **reusable**, strongly-typed code. Prefer small composable primitives over
copy-paste. Code should read well without needing comments to explain *what* it does.

## Reuse & abstraction — bias toward DRY (aggressive)

David prefers reusable code. **Design for reuse from the start**, not after the third copy.

- Before writing logic, check `lib/`, `utils/`, `src/utils/`, shared `hooks/`,
  `components/shared/`, and existing services for something to reuse or extend.
- Factor cross-cutting behaviour into typed primitives — like the ones already in
  these repos: `cn()`, `globalFetch()` / `assertApiOk()`, `sendResponse()`,
  `catchAsync()`, `ApiError`, `optionalOrEmpty()`, `commonSchemas`,
  `transformPrismaData`. New helpers should feel like they belong next to these.
- A function/component doing two jobs → split it. Repeated JSX → extract a component.
  Repeated query/mutation → a `useXxx` hook. Repeated request shaping → a service fn.
- Centralise constants, config, and types — never hard-code a value that appears twice
  (URLs, table/field IDs, status strings, colours). Put them in `constants.ts` / config.
- **Don't** over-engineer for imaginary futures. Reuse means "factor what genuinely
  recurs or is clearly cross-cutting," not "add config knobs nobody asked for."

## TypeScript rigor — strict but pragmatic

- `strict: true`. Explicit return types and param types on **exported** functions and
  public APIs. Let inference handle obvious locals.
- `noUnusedLocals` / `noUnusedParameters` stay **off**; prefix intentionally-unused
  params with `_` (e.g. `(_req, res)`).
- Avoid `any` in application code. `any` is acceptable **only at I/O boundaries**
  (raw Airtable/Prisma/3rd-party payloads) — shape it into a typed model immediately
  after (see `transformPrismaData`, `extractField`).
- Define and **export** `type`/`interface` for domain models, request/response shapes,
  and component props. Co-locate types with their feature or in a `types/` dir.
- Prefer `type` for unions/shapes; `interface` is fine for extendable object contracts.
  Use discriminated unions over loose optional grab-bags.

## Comments — minimal

Self-documenting code first. Good names and types carry the meaning.

- Comment **only** genuinely non-obvious things: a tricky algorithm, a workaround, a
  business rule, or *why* a surprising choice was made — never narrate what the code
  plainly does.
- No JSDoc by default. Add it only on a widely-shared primitive/util that others import,
  or when explicitly asked. Keep it short.
- Delete commented-out code; don't ship `// TODO` graveyards or `old.txt`-style dumps.

## Naming & conventions

- Files: components `PascalCase.tsx`; everything else (utils, services, hooks, routes,
  controllers) `camelCase.ts`. Hooks start with `use` (`useShippingRequests`).
- Express controllers: handler functions end in `Handler` (`createUserHandler`),
  services are plain verbs (`createUser`, `updateUser`).
- Variables/functions `camelCase`; types/components/classes `PascalCase`;
  true constants `SCREAMING_SNAKE_CASE` (`ERROR_CODES`, `API_BASE_URL`).
- Booleans read as predicates: `isActive`, `hasAccess`, `isMissing`, `isFuture`.
- Use path aliases instead of deep relative imports: `@/services/...`, `@/lib/...`.
- Import order: external packages → aliased internal (`@/...`) → relative → styles.

## Error handling

- Never swallow errors silently. Surface a real message to the caller/UI.
- Throw typed/operational errors with a code + message (backend: `ApiError` +
  `ERROR_CODES`); convert unknown errors into a friendly message at the boundary.
- Validate input at the edge (Joi on Express, Zod on React forms) before it reaches
  business logic. Don't trust client data.
- One standard response envelope per surface and stick to it (see `sendResponse`,
  `ApiResponse`, `assertApiOk`).

## Tooling defaults

- Package manager: **npm** (lockfile committed).
- Server state: **TanStack Query**. Client/global state: **React Context + hooks** —
  reach for Context only when truly cross-cutting (auth, theme); prefer URL state,
  server state, and local state otherwise. No Redux/Zustand unless asked.
- Tests: write them alongside features (vitest/jest for TS, pytest for Python). Cover
  core business logic and utilities well; UI smoke-test the critical paths.
- Secrets via env vars only — never hard-code keys/tokens. Provide `example.env`.

## Do / Don't

**Do**
- Reuse and extend existing helpers before writing new ones.
- Keep functions small and single-purpose; return early to avoid nesting.
- Type the boundaries; thread types through.
- Co-locate by feature where the stack supports it.

**Don't**
- Copy-paste a block a second time instead of extracting it.
- Sprinkle `any`, `// @ts-ignore`, or `eslint-disable` to silence the compiler.
- Hard-code values that recur (IDs, URLs, colours, status strings).
- Add narrating comments, dead code, or speculative abstraction.
- Introduce a new library when an existing dependency already does the job.
