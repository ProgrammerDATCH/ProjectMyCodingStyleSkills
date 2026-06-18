---
name: nextjs-dashboard
description: >-
  David's standard for building Next.js 15 (App Router) dashboards and full-stack
  web apps — the default for new frontends. Use whenever creating or editing a
  Next.js app: pages/layouts under app/, route handlers in app/api/*/route.ts,
  React 19 components, shadcn/ui + Tailwind v4, TanStack Query data hooks,
  next-auth, recharts, and integrations (Airtable, Xero, OpenAI, nodemailer).
  Matches the KABISA dashboards (Shipping, KPI, Receivables). Covers folder
  layout, the components/ui vs components/shared split, hooks/ + lib/ patterns,
  and Vercel deploy. Pair with coding-principles.
---

# Next.js 15 dashboard (David's standard)

Default for new frontend / full-stack web apps. Self-contained: UI + API routes in one
Next.js app, deployed on Vercel. (For a SPA against a separate backend, see
`react-vite-app`; for a standalone API, see `express-prisma-api`.)

## Stack

Next.js 15 **App Router** (`next dev --turbopack`) · React 19 · TypeScript ·
Tailwind **v4** (`@tailwindcss/postcss`) · shadcn/ui (Radix) · `cn()` + `tailwind-merge` ·
lucide-react · **TanStack Query** (server state) · next-auth · recharts · date-fns ·
react-day-picker. Integrations as needed: nodemailer, openai, Airtable REST, Xero.
Package manager **npm**.

## Folder layout

```
app/
  layout.tsx          root layout
  providers.tsx       'use client' — QueryClientProvider, SessionProvider, theme
  page.tsx            dashboard
  globals.css         Tailwind v4 + design tokens
  <section>/page.tsx  e.g. analytics/page.tsx, access-denied/page.tsx
  api/<resource>/route.ts   route handlers (server-side integrations)
components/
  ui/        shadcn primitives (Button, Dialog, Select…) — generated, minimally edited
  shared/    app components: layout, GlobalFilter, charts, skeletons, ErrorDisplay
hooks/       useXxx data hooks (TanStack Query) — useShippingRequests, usePayments
lib/         utils.ts (cn), constants.ts (IDs/keys), domain helpers, integration clients
```

- `components/ui` = reusable shadcn primitives. `components/shared` = composed app pieces.
  A piece used by 2+ pages belongs in `shared`, not copy-pasted.
- Cross-cutting client state (auth/theme) via Context in `providers.tsx`; otherwise lean
  on TanStack Query + local state + URL params.

## Data fetching — TanStack Query hooks

Each resource gets a typed `useXxx` hook. Export the row/response **types** from the hook;
keep the query key and fetch in one place.

```ts
// hooks/useShippingRequests.ts
import { useQuery } from '@tanstack/react-query';

export type ShippingRecord = { carId: string; model: string; /* …explicit fields… */ };

async function fetchShippingRequests(): Promise<ShippingRecord[]> {
  const res = await fetch('/api/shipping');
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
}

export function useShippingRequests() {
  return useQuery({ queryKey: ['shipping-requests'], queryFn: fetchShippingRequests });
}
```

Components consume `{ data, isLoading, error }` and render a `DashboardSkeleton` while
loading and `ErrorDisplay` on error — don't re-implement loading/error UI per page.

## Route handlers (server side)

External APIs (Airtable, Xero, OpenAI, mail) are called from `app/api/*/route.ts`, never
from the browser — keeps keys server-side.

```ts
// app/api/shipping/route.ts
import { NextResponse } from 'next/server';

const AIRTABLE_API_KEY = process.env.AIRTABLE_API_KEY!;
const BASE_ID = process.env.AIRTABLE_BASE_ID!;       // not hard-coded inline

export async function GET() {
  try {
    const records = await fetchAirtableRecords(SHIP_TABLE_ID);
    return NextResponse.json(records.map(toShippingRecord));
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Unknown error' },
      { status: 500 },
    );
  }
}
```

- Factor integration plumbing into reusable helpers (`fetchAirtableRecords` with offset
  pagination, `extractField`, `normalizeDate`) in `lib/` — they recur across routes.
- Move table/field IDs and base IDs into `lib/constants.ts` or env, not scattered literals.
- Validate/normalise the external payload into a typed model before returning to the client
  (the `any` boundary rule).

## UI conventions

- Build screens from `components/ui` shadcn primitives; style with Tailwind utilities and
  `cn()` for conditional classes. No ad-hoc CSS files or inline `style={{}}` for theming.
- Icons: lucide-react. Charts: recharts. Dates: date-fns + react-day-picker.
- Centralise brand tokens (colours, fonts, spacing) in `globals.css` / Tailwind theme —
  never hard-code hex values in components.
- Mark interactive components `'use client'`; keep server components for data/layout where
  possible. Standard pieces: `GlobalFilter`, skeletons, `ErrorDisplay`, `QueryProvider`.

## Auth

next-auth (`next-auth` v4): config under `app/api/auth/[...nextauth]`, `SessionProvider`
in `providers.tsx`, gate pages/handlers by session, redirect unauthorised users to
`app/access-denied`.

## Scripts & deploy

`dev: next dev --turbopack`, `build: next build`, `start`, `lint`. Deploy on **Vercel**
(`vercel.json`). Secrets in Vercel env / `.env.local`; never commit them.

## Do / Don't

**Do** call external APIs from route handlers · extract integration helpers to `lib/` ·
type hook responses and export the types · reuse `shared` components, skeletons, and
`ErrorDisplay` · keep IDs/keys in constants/env.

**Don't** fetch third-party APIs (with keys) from the client · copy a component into a
second page instead of moving it to `shared` · hard-code Airtable/Xero IDs or hex colours
inline · hand-roll loading/error UI per page · drop `any` on payloads without shaping them.
