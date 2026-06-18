---
name: python-app
description: >-
  David's standard for Python data/analytics apps and dashboards built with
  Streamlit (e.g. kabisa-cashflow). Use when creating or editing a Python project:
  the app/ layered layout (ui/views, engine, db, connectors), a theme module for
  all styling, pandas/plotly for data + charts, psycopg/SQLite for storage,
  external connectors (Xero, Airtable), pytest with hand-seeded fixtures, pinned
  requirements, and Docker deploy. Pair with coding-principles.
---

# Python app (David's standard)

For Python data/analytics tools and internal dashboards — typically **Streamlit**.

## Stack

Streamlit (+ streamlit-extras, streamlit-sortables) · pandas · plotly · rapidfuzz ·
openpyxl · requests · python-dotenv · psycopg (Postgres) / SQLite · pytest. **Pin exact
versions** in `requirements.txt` (`streamlit==1.57.0`). Run in a `.venv`.

## Layered layout

```
app/
  ui/
    main.py        app entry: wiring, global CSS injection, nav
    theme.py       COLORS, fonts, helpers: status_badge, section_header, metric_strip
    auth.py, caches.py, links.py, buildinfo.py
    views/         ONE file per sidebar entry: dashboard.py, receivables.py, payables.py…
    assets/
  engine/          business logic: forecast.py, fx.py, chunks.py, delays.py, refresh.py…
  db/              connection.py, database.py, schema.py, sql.py — storage access
  connectors/      external sources: xero.py, xero_oauth.py, airtable.py
tests/             pytest, hand-seeded fixtures
scripts/           one-off/maintenance scripts
docs/              style-guide.md and design docs
```

Separation (same spirit as the Express layering):

- **views** render UI only; they call **engine** for computation and **db** for data.
- **engine** holds pure-ish business logic; keep it free of Streamlit calls so it's testable.
- **db** owns all SQL/connection handling — views/engine don't open raw connections when a
  helper exists.
- **connectors** wrap third-party APIs (Xero, Airtable) behind typed functions.

## Styling — theme module, never inline

All styling goes through `app/ui/theme.py`. Read `docs/style-guide.md` before any UI change.

- Pull colours from `theme.COLORS["…"]`; **never** hard-code hex codes in `app/ui/`.
- Use helpers: `theme.status_badge(text, kind)`, `theme.section_header(title, subtitle)`,
  `theme.metric_strip([...])` — don't paste `<span style="color:…">` markup.
- Inject global CSS **once** via `theme.inject_global_css()` (wired in `main.py`); no
  page-level `<style>` blocks.
- Reserve `type="primary"` buttons for the single principal action in a context.

## Code conventions

- `snake_case` for functions/variables/modules, `PascalCase` for classes,
  `SCREAMING_SNAKE_CASE` for constants. Each package has `__init__.py`.
- Add **type hints** on function signatures; return typed values. Use `pandas`/`plotly`
  idiomatically; prefer vectorised pandas over Python loops.
- Reuse engine/db/theme helpers aggressively — factor repeated transforms into `engine/`,
  repeated queries into `db/sql.py`. No copy-pasted SQL or formatting.
- Config/secrets via `python-dotenv` env vars; ship an example env. Never hard-code keys.

## Testing — pytest

Tests live in `tests/`, run with `.venv/bin/python -m pytest -q` and must pass before
declaring work done. Seed data by hand with small helpers (e.g. `_seed_fx`, `_seed_xero_ar`,
`_seed_chunk`) rather than depending on live external data — see `tests/test_forecast.py`.
Cover engine logic and db/sql well.

## Deploy

Dockerfile + `deployment/`. Pinned `requirements.txt` so the image is reproducible. If a
repo's `.claude` Stop hook auto-commits each turn, don't manually `git commit` unless asked.

## Do / Don't

**Do** keep views thin and engine testable · route styling through `theme.py` · pin
dependency versions · type signatures · seed pytest fixtures by hand · centralise SQL in
`db/`.

**Don't** hard-code hex colours or inline `<style>` in `app/ui/` · open raw DB connections
when a `db/` helper exists · call third-party APIs outside `connectors/` · loop over rows
when pandas can vectorise · commit secrets.
