# XAffordsFX – Professional Forex Journal

A complete single-page Forex trading journal with dashboard, calendar heatmap, journal history, analytics, multi-account support, and screenshot attachments.

## Current Status

- **Original frontend** (`index.html`) – left **completely unchanged** (still uses localStorage).
- **Supabase backend** – fully prepared from scratch.

## Files

| File / Folder              | Description                                      |
|---------------------------|--------------------------------------------------|
| `index.html`              | Original app (localStorage) – **do not modify** |
| `supabase/schema.sql`     | Complete database schema + RLS policies          |
| `SUPABASE_SETUP.md`       | Full step-by-step guide to set up Supabase       |

## Quick Start (Supabase)

1. Create a new project at [supabase.com](https://supabase.com).
2. Open the SQL Editor and run the entire contents of `supabase/schema.sql`.
3. Create a private Storage bucket named `trade-screenshots`.
4. Apply the storage policies listed in `SUPABASE_SETUP.md`.
5. Follow the rest of the guide in `SUPABASE_SETUP.md`.

Once the backend is ready, the original `index.html` can stay as a pure local version while a new Supabase-powered frontend is built in parallel.

---

Built for professional traders who want clean data, strict process tracking, and beautiful analytics.
