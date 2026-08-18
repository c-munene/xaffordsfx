# XAffordsFX — Supabase Setup (reconnected from scratch)

## Project
- URL: `https://zalffliufmwajxcwkzrq.supabase.co`
- Anon key is embedded in `index.html`

## Database
Run the SQL in the Supabase SQL Editor (see `supabase_schema.sql`).

Tables:
- `profiles` (id, username, email)
- `accounts` (id, user_id, name, starting_balance)
- `trades` (id, account_id, user_id, date, pair, direction, entry, exit, sl, tp, lots, pl, screenshots, entry_reasoning, exit_notes, multiplier)

RLS is enabled so users only see their own data.

A trigger on `auth.users` automatically creates a profile + "Main Account" on signup.

## Auth
- Email/password
- Confirm email should be **OFF** in Authentication → Providers → Email

## Frontend
Single-page app (`index.html`) uses the Supabase JS client (CDN).

- Signup / Login / Logout → Supabase Auth
- Accounts & trades → real-time DB queries
- Multi-device: log in anywhere with the same email/password and see the same data

## Live site
GitHub Pages: https://c-munene.github.io/xaffordsfx/
