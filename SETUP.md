# XAffordsFX ↔ Supabase – Full Connection Setup

Live site: https://c-munene.github.io/xaffordsfx/  
Supabase project: `https://zalffliufmwajxcwkzrq.supabase.co`

The frontend is already wired (URL + anon key in `index.html`).  
What was missing: **table grants + RLS policies + signup trigger**.

## 1. Run the SQL (required – 2 minutes)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project `zalffliufmwajxcwkzrq`
2. Go to **SQL Editor** → **New query**
3. Paste the entire contents of [`supabase_schema.sql`](./supabase_schema.sql)
4. Click **Run**

You should see success (no errors). This will:

- Ensure `profiles`, `accounts`, `trades` tables exist with the correct columns
- Grant permissions to `authenticated` / `anon`
- Enable Row Level Security so each user only sees their own data
- Auto-create a profile + **Main Account** when someone signs up

## 2. Auth settings (recommended)

**Authentication → Providers → Email**

- Email provider: **Enabled**
- For quick testing: turn **Confirm email** OFF (so signup works immediately without inbox)
- Or leave confirmation ON and use a real email you can access

## 3. Test the connection

1. Open https://c-munene.github.io/xaffordsfx/
2. **Sign up** with email + password + username
3. You should land on the Dashboard with a **Main Account** ($10,000)
4. Log a trade → it should appear in Journal and persist after refresh
5. Open another browser / incognito → data should still be there after login

## 4. Verify in Supabase

- **Table Editor** → `profiles` / `accounts` / `trades` should show your rows
- **Authentication → Users** should list the new user

## Schema overview (matches the app)

| Table     | Key columns |
|-----------|-------------|
| profiles  | `id` (FK auth.users), `username` |
| accounts  | `id`, `user_id`, `name`, `starting_balance`, `created_at` |
| trades    | `id`, `account_id`, `user_id`, `date`, `pair`, `direction`, `entry`, `exit`, `sl`, `tp`, `lots`, `pl`, `screenshots` (jsonb), `entry_reasoning` (jsonb), `exit_notes` (jsonb), `multiplier` |

Screenshots are stored as base64 data URLs inside the `screenshots` JSON array (no Storage bucket required).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `permission denied for table accounts` | You have not run `supabase_schema.sql` yet (or grants failed) |
| Signup works but empty dashboard | Trigger not installed – re-run the SQL |
| "Email not confirmed" | Disable confirm email or confirm via the link |
| Login fails after signup | Check Authentication → Users; confirm user exists |

## Security note

The anon key in `index.html` is **public by design** (browser apps). Real security is RLS + policies in this SQL file. Never put the **service_role** key in frontend code.
