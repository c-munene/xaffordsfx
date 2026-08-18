# XAffordsFX – Professional Forex Journal

A complete single-page Forex trading journal with dashboard, calendar heatmap, journal history, analytics, multi-account support, and screenshot attachments.

## Current Status (August 18, 2026)

| Component | Status | Notes |
|-----------|--------|-------|
| **Original frontend** (`index.html`) | ✅ Complete & unchanged | Pure localStorage version – never modify |
| **Supabase schema** (`supabase/schema.sql`) | ✅ Complete | Tables + RLS + triggers + `account_summary` view |
| **Setup guide** (`SUPABASE_SETUP.md`) | ✅ Complete | Step-by-step for dashboard + storage |
| **Supabase-powered frontend** (`index-supabase.html`) | 🔄 Building now | Parallel version with real Auth + cloud data |

## Live Demo

- **LocalStorage version**: [https://c-munene.github.io/xaffordsfx/](https://c-munene.github.io/xaffordsfx/)
- **Supabase version** (once live): [https://c-munene.github.io/xaffordsfx/index-supabase.html](https://c-munene.github.io/xaffordsfx/index-supabase.html)

## Quick Start – Supabase Backend (do this first)

1. Create a new project at [supabase.com](https://supabase.com).
2. Open **SQL Editor** → New query → paste the entire contents of `supabase/schema.sql` → Run.
3. Go to **Storage** → New bucket → name it `trade-screenshots` → make it **Private**.
4. Run the storage policies listed in `SUPABASE_SETUP.md`.
5. Go to **Project Settings → API** and copy:
   - Project URL
   - `anon` public key

## Quick Start – Supabase Frontend

1. Open `index-supabase.html`.
2. At the very top of the `<script>` section replace the two placeholders:

```js
const SUPABASE_URL = 'YOUR_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

3. Open the page, sign up with email + username + password, and start journaling.

## Files

| File / Folder | Description |
|---------------|-------------|
| `index.html` | Original app (localStorage) – **do not modify** |
| `index-supabase.html` | Parallel Supabase-powered version |
| `supabase/schema.sql` | Complete database schema + RLS policies |
| `SUPABASE_SETUP.md` | Full step-by-step guide to set up Supabase |

---

Built for professional traders who want clean data, strict process tracking, and beautiful analytics.
