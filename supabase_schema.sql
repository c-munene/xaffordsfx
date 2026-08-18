-- ============================================================
-- XAffordsFX – Complete Supabase Schema + RLS (from scratch)
-- Run this ONCE in: Supabase Dashboard → SQL Editor → New query
-- Project: https://zalffliufmwajxcwkzrq.supabase.co
-- ============================================================

create extension if not exists "pgcrypto";

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Accounts
create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Main Account',
  starting_balance numeric(18,2) not null default 10000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists accounts_user_id_idx on public.accounts(user_id);

-- Trades
create table if not exists public.trades (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz not null default now(),
  pair text not null,
  direction text not null check (direction in ('Buy', 'Sell')),
  entry numeric,
  exit numeric,
  sl numeric,
  tp numeric,
  lots numeric,
  pl numeric,
  screenshots jsonb default '[]'::jsonb,
  entry_reasoning jsonb default '{}'::jsonb,
  exit_notes jsonb default '{}'::jsonb,
  multiplier numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists trades_user_id_idx on public.trades(user_id);
create index if not exists trades_account_id_idx on public.trades(account_id);
create index if not exists trades_date_idx on public.trades(date desc);

-- Grants
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select on public.profiles to anon;
grant select, insert, update, delete on public.accounts to authenticated;
grant select on public.accounts to anon;
grant select, insert, update, delete on public.trades to authenticated;
grant select on public.trades to anon;

-- RLS
alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.trades enable row level security;

-- Clean old policies
do $$
declare r record;
begin
  for r in (select policyname, tablename from pg_policies where schemaname = 'public' and tablename in ('profiles','accounts','trades')) loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- Profiles policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Accounts policies
create policy "Users can view own accounts" on public.accounts for select using (auth.uid() = user_id);
create policy "Users can insert own accounts" on public.accounts for insert with check (auth.uid() = user_id);
create policy "Users can update own accounts" on public.accounts for update using (auth.uid() = user_id);
create policy "Users can delete own accounts" on public.accounts for delete using (auth.uid() = user_id);

-- Trades policies
create policy "Users can view own trades" on public.trades for select using (auth.uid() = user_id);
create policy "Users can insert own trades" on public.trades for insert with check (auth.uid() = user_id);
create policy "Users can update own trades" on public.trades for update using (auth.uid() = user_id);
create policy "Users can delete own trades" on public.trades for delete using (auth.uid() = user_id);

-- Auto-create profile + Main Account on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do update set username = excluded.username, email = excluded.email, updated_at = now();

  insert into public.accounts (user_id, name, starting_balance)
  values (new.id, 'Main Account', 10000);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- updated_at helper
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists accounts_updated_at on public.accounts;
create trigger accounts_updated_at before update on public.accounts for each row execute function public.set_updated_at();
drop trigger if exists trades_updated_at on public.trades;
create trigger trades_updated_at before update on public.trades for each row execute function public.set_updated_at();
