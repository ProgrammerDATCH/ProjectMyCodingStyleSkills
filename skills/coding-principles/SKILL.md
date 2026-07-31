---
name: coding-principles
description: >-
  Akokuntaro Coding Skills — David's universal coding standards: clean, reusable,
  strongly-typed code.
  Apply on ANY coding task in his repos (TypeScript, JavaScript, React,
  Node/Express, Python): how to name things, when to extract/abstract for reuse,
  how strict TypeScript should be, commenting density, error handling, and the
  do/don't list that keeps code consistent. Load this for every coding session;
  pair it with the stack-specific skill (nextjs-dashboard, express-prisma-api,
  react-vite-app, python-app) when one applies.
---

# Coding principles — Akokuntaro Coding Skills (David's defaults)

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

- Name in **plain, common English** — specific and unambiguous (`pendingInvoices`, not
  `data2`, `tmp`, or `procInvLst`). Avoid abbreviations, jargon, and cleverness; a name
  should read like the thing it holds. The same plain-English rule governs any text users
  see (see the UI skills' copy rules).
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

## Scope & verification — finish the job, then prove it

The two ways work comes back rejected are **narrowing the ask** and **calling it done without
driving it**. Both are avoidable.

### Read the ask for INTENT, not just the literal targets

A request that names two URLs is naming examples, not a whitelist. Before building, ask *who
performs this action and where* — then cover every one of those places.

- "Add the envelope on `head-teacher/class-attendance`" means **every register screen** where
  somebody takes attendance. A teacher takes one on their own page; if the feature can be assigned
  *to* a teacher, the teacher's page needs it too.
- Enumerate the surfaces before coding: which roles reach this, which routes render it, which pages
  duplicate the same component. If a surface is deliberately out of scope, say so in the reply —
  never leave it silently undone.
- When two readings differ materially and you can't resolve it from the code, ask. Otherwise pick
  the WIDER reading and state the assumption.

### Test every role the change can affect

Role-scoped apps break per-role, not globally. A change to a shared endpoint or a scoping rule is
not tested until it has been exercised **as each role that reaches it**.

- List the affected roles first (the permission grant, the sidebar `roles`, the backend's own
  allowlist — they disagree more often than not), then run the surface as each one.
- Script it when the list is long: log in per role, hit the endpoint, assert the shape. A dozen curl
  calls in a loop find in one minute what clicking finds in an hour.
- The role you changed the behaviour FOR is the one most likely to be broken — test it first, not
  last.

### Drive the feature, don't just load it

"The page renders" is not verification. Renders, then **interacts**:

- Click through every state the change introduced: open the popup, drill the map, submit the form,
  switch the tab, page to page 2, toggle the filter, and go back.
- Verify the numbers, not just the absence of an error. A drill that returns 0 where its parent said
  1,079 is a passing request and a broken feature.
- Check both the empty case and a case with real data — an empty dataset hides most bugs.
- Read the network log and the console, not only the screenshot.

### Then say plainly what you did and did NOT verify

Report the surfaces exercised and the ones left untested, with the reason. "Verified" must mean
driven; if it only compiled, say that instead.

## Do / Don't

**Do**
- Reuse and extend existing helpers before writing new ones.
- Keep functions small and single-purpose; return early to avoid nesting.
- Type the boundaries; thread types through.
- Co-locate by feature where the stack supports it.
- Name things — and write any user-facing text — in plain, specific, common English.

**Don't**
- Narrow a request to the literal URLs/files it named while leaving the same feature broken next door.
- Report work as done or verified when it was only compiled, or only exercised as one role.
- Copy-paste a block a second time instead of extracting it.
- Sprinkle `any`, `// @ts-ignore`, or `eslint-disable` to silence the compiler.
- Hard-code values that recur (IDs, URLs, colours, status strings).
- Add narrating comments, dead code, or speculative abstraction.
- Introduce a new library when an existing dependency already does the job.
