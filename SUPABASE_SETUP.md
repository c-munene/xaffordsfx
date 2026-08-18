# XAffordsFX → Supabase Integration Guide

**Important:** The original `index.html` has been left **100% unchanged**.  
This guide sets up a complete Supabase backend from scratch so you can later connect a frontend to it.

---

## Step 1 – Create a new Supabase project

1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New Project**.
3. Choose organization → enter project name (e.g. `xaffordsfx`).
4. Set a strong database password (save it).
5. Choose a region close to your users.
6. Click **Create new project** and wait until it is ready.

---

## Step 2 – Run the database schema

1. In the Supabase dashboard go to **SQL Editor**.
2. Click **New query**.
3. Copy the entire contents of `supabase/schema.sql` from this repository.
4. Paste it into the editor and click **Run**.
5. Confirm there are no errors.

This creates:

- `profiles` (linked to Supabase Auth)
- `trading_accounts`
- `trades`
- `trade_screenshots`
- All necessary indexes
- Full Row Level Security (RLS) policies
- Automatic profile creation on signup
- Helpful `account_summary` view

---

## Step 3 – Create Storage bucket for screenshots

1. Go to **Storage** in the left sidebar.
2. Click **New bucket**.
3. Name: `trade-screenshots`
4. Make it **Private** (recommended).
5. Click **Create bucket**.

### Storage policies (run in SQL Editor)

```sql
-- Allow authenticated users to upload screenshots into their own folder
create policy "Users can upload own screenshots"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'trade-screenshots'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own screenshots
create policy "Users can view own screenshots"
on storage.objects for select
to authenticated
using (
  bucket_id = 'trade-screenshots'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own screenshots
create policy "Users can delete own screenshots"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'trade-screenshots'
  and (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## Step 4 – Enable Email Auth (and optional username)

1. Go to **Authentication → Providers**.
2. Make sure **Email** is enabled.
3. (Optional but recommended) Under **Authentication → Settings**:
   - Disable “Confirm email” while testing (re-enable later).
   - Or keep it enabled for production.

The schema already supports usernames via `raw_user_meta_data`.

---

## Step 5 – Get your project keys

1. Go to **Project Settings → API**.
2. Copy:
   - **Project URL**
   - **anon public** key
   - **service_role** key (keep this secret – never put it in frontend code)

You will need the URL + anon key when you later connect a frontend.

---

## Step 6 – Recommended next steps (when you are ready to change the frontend)

Because the original `index.html` must stay untouched, the recommended approach is:

1. Create a new file (e.g. `index-supabase.html` or a proper Vite/React/Vue project).
2. Install `@supabase/supabase-js`.
3. Replace all `localStorage` logic with Supabase Auth + database queries.
4. Upload screenshots to the `trade-screenshots` bucket instead of storing base64.
5. Use the `account_summary` view for dashboard metrics.

### Example client initialization (for future use)

```js
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'YOUR_PROJECT_URL'
const supabaseAnonKey = 'YOUR_ANON_KEY'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### Example: Create a trading account

```js
const { data, error } = await supabase
  .from('trading_accounts')
  .insert({
    name: 'Main Account',
    starting_balance: 10000,
    is_default: true
  })
  .select()
  .single()
```

### Example: Log a trade

```js
const { data, error } = await supabase
  .from('trades')
  .insert({
    account_id: currentAccountId,
    trade_date: new Date().toISOString(),
    pair: 'EURUSD',
    direction: 'Buy',
    entry_price: 1.0850,
    exit_price: 1.0900,
    lots: 0.10,
    pl: 50.00,
    // ... entry reasoning + exit notes fields
  })
```

---

## Data Model Mapping (localStorage → Supabase)

| localStorage concept          | Supabase table / feature          |
|-------------------------------|-----------------------------------|
| `xaffordsfx_users`            | `auth.users` + `profiles`         |
| `xaffordsfx_accounts_{user}`  | `trading_accounts`                |
| trades array                  | `trades`                          |
| base64 screenshots            | Storage bucket + `trade_screenshots` |
| current user                  | `supabase.auth.getUser()`         |
| current account               | filter by `user_id` + `is_default` or store preference |

---

## Security notes

- All tables have RLS enabled – users can only see/edit their own data.
- Screenshots are stored privately under `user_id/...` paths.
- Never expose the `service_role` key in the browser.
- The original simple hash password system is replaced by proper Supabase Auth (bcrypt + JWT).

---

## Status

- ✅ Original `index.html` – **untouched**
- ✅ Complete database schema + RLS
- ✅ Storage bucket policies ready
- ✅ Step-by-step setup documented

When you are ready for the frontend migration (while still keeping the original file), just say the word and I will create a parallel Supabase-powered version.
