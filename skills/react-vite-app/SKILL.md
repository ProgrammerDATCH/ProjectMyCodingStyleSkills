---
name: react-vite-app
description: >-
  David's standard for SPA frontends built with Vite + React 18 + TypeScript that
  talk to a SEPARATE backend API (e.g. an express-prisma-api). Use when creating
  or editing a Vite React app: feature-based folders, react-router-dom routes,
  the lib/api.ts globalFetch + assertApiOk client over axios/fetch, typed service
  modules, react-hook-form + zod forms, shadcn/ui + Tailwind v3, sonner toasts,
  React Context for auth/theme. Matches Ireme-FrontEnd and UmutungoBox. Use this
  (not nextjs-dashboard) when the UI and API are deployed separately. Pair with
  coding-principles.
---

# Vite + React SPA (David's standard)

For a single-page app that consumes a **separate** backend API. (For a self-contained
full-stack dashboard, prefer `nextjs-dashboard`.) These projects originate from Lovable
(`vite_react_shadcn_ts`) and are then extended by hand.

## Stack

Vite 5 · React 18 · TypeScript · react-router-dom v6 · shadcn/ui (Radix) +
Tailwind **v3** + `cn()` · **TanStack Query** (server state) · axios/fetch wrapper ·
**react-hook-form + zod** (`@hookform/resolvers`) · **sonner** toasts · lucide-react /
react-icons · date-fns · framer-motion · recharts. Build with `@vitejs/plugin-react-swc`.
Package manager **npm**.

## Folder layout — feature-based

```
src/
  main.tsx, App.tsx
  features/<feature>/    api.ts, components, hooks, types — self-contained slices
  pages/                 route-level screens
  components/            ui/ (shadcn) + shared app components
  hooks/                 cross-feature hooks (incl. hooks/api)
  lib/                   api.ts (globalFetch/assertApiOk), api-base-url.ts, <domain>-services.ts
  contexts/              AuthContext, ThemeContext — cross-cutting client state
  types/                 shared domain types
  utils/                 pure helpers
```

Prefer **feature folders** for new domains (`features/<x>/` owns its api, components,
hooks, types). Truly shared things go up to `components/`, `hooks/`, `lib/`, `types/`.

## API layer — one client, typed services

All HTTP goes through the shared `globalFetch` in `lib/api.ts` (base URL from
`api-base-url.ts`, auth header, params, FormData handling). It returns an envelope and
**does not throw** on HTTP errors; `assertApiOk` unwraps it so React Query mutations
reject properly.

```ts
// lib/api.ts (shape)
export interface ApiResponse<T = unknown> { status: number; data: T; error: string }

export function assertApiOk<T>(res: ApiResponse<T>): T {
  const payload = res.data as { status?: string; message?: string } | undefined;
  const httpOk = res.status >= 200 && res.status < 300;
  const apiError = payload?.status === 'error';
  if (!httpOk || apiError) {
    throw new Error(payload?.message || res.error || `Request failed (${res.status})`);
  }
  return res.data;
}
```

Wrap endpoints in typed service modules (`lib/<domain>-services.ts` or
`features/<x>/api.ts`) — components/hooks call services, never `fetch` directly.

```ts
// features/students/api.ts
import { globalFetch, assertApiOk } from '@/lib/api';

export async function getStudents(): Promise<Student[]> {
  return assertApiOk(await globalFetch('/students')) as Student[];
}
export async function createStudent(body: CreateStudentInput): Promise<Student> {
  return assertApiOk(await globalFetch('/students', { method: 'POST', body })) as Student;
}
```

Consume via TanStack Query hooks:

```ts
export function useStudents() {
  return useQuery({ queryKey: ['students'], queryFn: getStudents });
}
export function useCreateStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: createStudent,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['students'] }); toast.success('Saved'); },
    onError: (e) => toast.error(e.message),
  });
}
```

## Forms — react-hook-form + zod

Schema-first. Define a zod schema, infer the type, wire with `zodResolver`, render with
shadcn `Form` components. Show errors inline; toast on submit success/failure via sonner.

```ts
const schema = z.object({ email: z.string().email(), name: z.string().min(1) });
type FormValues = z.infer<typeof schema>;
const form = useForm<FormValues>({ resolver: zodResolver(schema) });
```

## Routing & state

- `react-router-dom` v6: route table in `App.tsx`, route screens in `pages/`, lazy-load
  heavy routes. Protect routes with an auth wrapper reading `AuthContext`.
- Server state → TanStack Query. Cross-cutting client state (auth/theme) → Context in
  `contexts/`. Otherwise local state + URL params. No Redux/Zustand unless asked.
- Notifications → **sonner** `toast`, one provider mounted at the root.

## UI conventions

Same as the Next stack: build from `components/ui` shadcn primitives, Tailwind v3
utilities + `cn()`, lucide-react icons, recharts, framer-motion for motion. Centralise
theme tokens; no inline style theming or hex literals in components.

### Inputs & controls — prefer a (searchable) select

- When the value comes from a **known set of options**, use a **select** — even for just a
  few. Reach for a free **text input only when capturing arbitrary/free-form data** (names,
  notes, amounts, search queries).
- **Every select must be searchable.** Use the shadcn **Combobox** (Popover + `Command`
  from `cmdk` — already a dependency) with a filter input, not a bare `<Select>`. Wire it
  to react-hook-form via a `Controller`; show empty/loading states in the popover.

```tsx
// Searchable select = Popover + Command (cmdk), bound through RHF Controller. Sketch:
<Controller name="country" control={control} render={({ field }) => (
  <Popover open={open} onOpenChange={setOpen}>
    <PopoverTrigger asChild>
      <Button variant="outline" role="combobox" className="w-full justify-between text-base">
        {field.value ? labelFor(field.value) : "Select…"}<ChevronsUpDown className="opacity-50" />
      </Button>
    </PopoverTrigger>
    <PopoverContent className="p-0">
      <Command>
        <CommandInput placeholder="Search…" />
        <CommandList>
          <CommandEmpty>No match.</CommandEmpty>
          {options.map((o) => (
            <CommandItem key={o.value} value={o.label}
              onSelect={() => { field.onChange(o.value); setOpen(false); }}>{o.label}</CommandItem>
          ))}
        </CommandList>
      </Command>
    </PopoverContent>
  </Popover>
)} />
```

### Responsive & typography — mobile-first, large fonts

- **Mobile-first always.** Base (unprefixed) Tailwind classes describe the small-screen
  layout; layer up with `sm: md: lg: xl:`. Single-column by default, grids at wider
  breakpoints. Never start desktop-only and patch mobile afterward.
- **Prefer large, readable type** and scale it **up** on big screens (`text-base md:text-lg`,
  headings `text-2xl lg:text-4xl`) — don't leave body text tiny on wide monitors. Generous
  spacing and tap targets (min ~44px); tables/charts scroll or reflow on mobile.

## Scripts & deploy

`dev: vite`, `build: vite build`, `build:dev`, `lint`, `preview`. Apps are Dockerised and
shipped to `ghcr.io/programmerdatch/...` via `docker buildx` (multi-arch). API base URL
comes from env / `api-base-url.ts` — never hard-code it.

## Do / Don't

**Do** route every request through `globalFetch` + `assertApiOk` · wrap endpoints in typed
services · organise new domains as feature folders · validate forms with zod · toast with
sonner · invalidate queries after mutations · use a searchable select (Combobox) for known
option sets · design mobile-first · keep type large and scale it up on big screens.

**Don't** call `fetch`/`axios` directly from a component · throw away the envelope (use
`assertApiOk` so mutations reject) · hard-code the API base URL · duplicate a service across
features · scatter loose `useState` where TanStack Query/Context belongs · use a text input
where a select fits · ship a non-searchable dropdown · start desktop-first or leave body
text tiny on large screens.
