-- ============================================================
-- XAffordsFX - Complete Supabase Schema (from scratch)
-- Original index.html is LEFT COMPLETELY UNCHANGED
-- ============================================================

-- 1. Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================
-- 2. Profiles (extends Supabase Auth)
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  email text,
  display_name text,
  avatar_url text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Auto-create profile when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 3. Trading Accounts
-- ============================================================
create table public.trading_accounts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  starting_balance numeric(18,2) not null default 10000.00,
  is_default boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,

  constraint trading_accounts_name_unique unique (user_id, name)
);

create index trading_accounts_user_id_idx on public.trading_accounts(user_id);

-- ============================================================
-- 4. Trades
-- ============================================================
create table public.trades (
  id uuid primary key default uuid_generate_v4(),
  account_id uuid not null references public.trading_accounts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,

  -- Core trade data
  trade_date timestamptz not null,
  pair text not null,
  direction text not null check (direction in ('Buy', 'Sell')),
  entry_price numeric(18,8) not null,
  exit_price numeric(18,8) not null,
  stop_loss numeric(18,8),
  take_profit numeric(18,8),
  lots numeric(12,4) not null default 0.10,
  multiplier numeric(18,4),
  pl numeric(18,4) not null default 0,

  -- Entry reasoning (checklist)
  entry_htf_structure boolean default false,
  entry_inverse_structure boolean default false,
  entry_breakout_zone boolean default false,
  entry_setup boolean default false,
  entry_tp_levels boolean default false,

  -- Exit notes & lessons
  plan_followed text check (plan_followed in ('Yes', 'No')),
  rules_followed text check (rules_followed in ('Yes', 'No')),
  what_differently text,
  market_structure text,
  trend_aligned text check (trend_aligned in ('Yes', 'No')),
  outcome_reason text,
  respected_sl text check (respected_sl in ('Yes', 'No')),
  size_appropriate text check (size_appropriate in ('Yes', 'No')),
  maintained_rr text check (maintained_rr in ('Yes', 'No')),
  tp_level text,

  -- Meta
  notes text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index trades_account_id_idx on public.trades(account_id);
create index trades_user_id_idx on public.trades(user_id);
create index trades_trade_date_idx on public.trades(trade_date desc);
create index trades_pair_idx on public.trades(pair);

-- ============================================================
-- 5. Trade Screenshots (metadata only – files live in Storage)
-- ============================================================
create table public.trade_screenshots (
  id uuid primary key default uuid_generate_v4(),
  trade_id uuid not null references public.trades(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,          -- e.g. user_id/trade_id/filename.jpg
  file_name text,
  file_size integer,
  mime_type text,
  created_at timestamptz default now() not null
);

create index trade_screenshots_trade_id_idx on public.trade_screenshots(trade_id);

-- ============================================================
-- 6. Updated_at triggers
-- ============================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger trading_accounts_updated_at
  before update on public.trading_accounts
  for each row execute procedure public.set_updated_at();

create trigger trades_updated_at
  before update on public.trades
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 7. Row Level Security (RLS)
-- ============================================================
alter table public.profiles enable row level security;
alter table public.trading_accounts enable row level security;
alter table public.trades enable row level security;
alter table public.trade_screenshots enable row level security;

-- Profiles policies
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Trading Accounts policies
create policy "Users can view own accounts"
  on public.trading_accounts for select
  using (auth.uid() = user_id);

create policy "Users can insert own accounts"
  on public.trading_accounts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own accounts"
  on public.trading_accounts for update
  using (auth.uid() = user_id);

create policy "Users can delete own accounts"
  on public.trading_accounts for delete
  using (auth.uid() = user_id);

-- Trades policies
create policy "Users can view own trades"
  on public.trades for select
  using (auth.uid() = user_id);

create policy "Users can insert own trades"
  on public.trades for insert
  with check (auth.uid() = user_id);

create policy "Users can update own trades"
  on public.trades for update
  using (auth.uid() = user_id);

create policy "Users can delete own trades"
  on public.trades for delete
  using (auth.uid() = user_id);

-- Screenshots policies
create policy "Users can view own screenshots"
  on public.trade_screenshots for select
  using (auth.uid() = user_id);

create policy "Users can insert own screenshots"
  on public.trade_screenshots for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own screenshots"
  on public.trade_screenshots for delete
  using (auth.uid() = user_id);

-- ============================================================
-- 8. Helpful views (optional but useful)
-- ============================================================
create or replace view public.account_summary as
select
  ta.id as account_id,
  ta.user_id,
  ta.name,
  ta.starting_balance,
  coalesce(sum(t.pl), 0) as total_pl,
  ta.starting_balance + coalesce(sum(t.pl), 0) as current_balance,
  count(t.id) as trade_count,
  count(t.id) filter (where t.pl > 0) as wins,
  count(t.id) filter (where t.pl < 0) as losses
from public.trading_accounts ta
left join public.trades t on t.account_id = ta.id
group by ta.id, ta.user_id, ta.name, ta.starting_balance;

-- ============================================================
-- DONE
-- Run this entire file in the Supabase SQL Editor
-- ============================================================
