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

### Copy & content — few words, plain English

- **Few words win.** Users skim; they hate walls of text. Keep labels, buttons, headings,
  and helper text short — cut every word that isn't doing a job. One tight line beats a
  paragraph, and most paragraphs shouldn't be on screen at all.
- **Plain, common English.** Write the way users talk — no jargon or internal terms.
  "Save" not "Persist", "Not paid" not "Outstanding remittance".
- **Be specific.** A label or message says exactly what it means: "Add invoice" not
  "Submit", "3 overdue" not "Some items need attention".
- **Summarise by default.** Lead with the headline number/status; tuck detail behind a
  click (tooltip, expandable row, drawer, "View details"). Don't dump full text up front.

### Inputs & controls — prefer a (searchable) select

- When the value comes from a **known set of options**, use a **select** — even when there
  are only a few. Reach for a free **text input only when capturing arbitrary/free-form
  data** the user makes up (names, notes, amounts, search queries).
- **Every select must be searchable.** Use the shadcn **Combobox** (Popover + `Command`
  from `cmdk`) with a filter input, not a bare `<Select>` dropdown. Add `cmdk` if the
  project doesn't have it yet. Show empty/loading states inside the popover.

```tsx
// Searchable select = shadcn Combobox (Popover + Command/cmdk). Sketch:
<Popover open={open} onOpenChange={setOpen}>
  <PopoverTrigger asChild>
    <Button variant="outline" role="combobox" className="w-full justify-between text-base">
      {value ? options.find((o) => o.value === value)?.label : "Select…"}
      <ChevronsUpDown className="opacity-50" />
    </Button>
  </PopoverTrigger>
  <PopoverContent className="p-0">
    <Command>
      <CommandInput placeholder="Search…" />
      <CommandList>
        <CommandEmpty>No match.</CommandEmpty>
        {options.map((o) => (
          <CommandItem key={o.value} value={o.label} onSelect={() => { onChange(o.value); setOpen(false); }}>
            {o.label}
          </CommandItem>
        ))}
      </CommandList>
    </Command>
  </PopoverContent>
</Popover>
```

### Responsive & typography — mobile-first, large fonts

- **Mobile-first always.** Write base (unprefixed) Tailwind classes for the small-screen
  layout, then layer up with `sm: md: lg: xl:`. Single-column by default; expand to grids
  at wider breakpoints. Never start desktop-only and bolt on mobile.
- **Prefer large, readable type**, and scale it **up** on big screens — don't leave body
  text tiny on wide monitors. e.g. `text-base md:text-lg`, headings `text-2xl lg:text-4xl`.
  Generous spacing and tap targets (min ~44px). Tables/charts get horizontal scroll or
  reflow on mobile rather than shrinking text.

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
`ErrorDisplay` · keep IDs/keys in constants/env · use a searchable select (Combobox) for
known option sets · design mobile-first · keep type large and scale it up on big screens ·
keep UI copy short, specific, and plain · summarise first and reveal detail on demand.

**Don't** fetch third-party APIs (with keys) from the client · copy a component into a
second page instead of moving it to `shared` · hard-code Airtable/Xero IDs or hex colours
inline · hand-roll loading/error UI per page · drop `any` on payloads without shaping them ·
use a text input where a select fits · ship a non-searchable dropdown · start desktop-first
or leave body text tiny on large screens · crowd the UI with long text, jargon, or vague labels.

## Role-scoped dashboards — find every surface before you build

These apps render the same feature from several routes (`[role]` segments, per-role static pages,
and components shared by both). Adding a control to one page is rarely the whole job.

- `grep` for the component and the route before coding; a feature belongs wherever its action is
  performed, not only on the page named in the ticket.
- Verify as each role that reaches it. The sidebar's `roles` array, the RBAC permission and the API's
  own allowlist frequently disagree — a link that 403s is a bug even though the code "works".
- Drive the change after it renders: open the dialog, drill the map, submit, page, toggle, go back.
  First paint hides nearly every real defect.

## Portalled UI inside a dialog

Radix `Select`, `Popover`, `Combobox` and `Tooltip` render in a portal at the end of `<body>`, so a
dialog with a raised `z-index` paints OVER them and the menu appears behind the dialog. When a dialog
sets its own stacking context, give the portalled content a higher `z-index` than the dialog — and
check it visually, since nothing warns you.
