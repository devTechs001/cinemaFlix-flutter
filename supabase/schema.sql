-- CinemaFlix — Supabase schema
-- Run this once in: Supabase Dashboard -> SQL Editor -> New query.
--
-- Tables used by the app:
--   profiles      (AuthService)
--   watchlist     (DatabaseService)
--   favorites     (DatabaseService)
--   reviews       (DatabaseService, joined with profiles for usernames)
--   watch_history (DatabaseService.updateWatchProgress, upsert on PK)
--   messages      (RealtimeService — needs Realtime enabled, see bottom)
--   app_updates   (UpdateService — insert rows via dashboard only)
--
-- Notes on id types: the app generates its own string ids for reviews and
-- chat messages, so those PKs are `text`. Tables where the app does not
-- send an id use `uuid default gen_random_uuid()`.

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  username text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are viewable by everyone"
  on public.profiles for select using (true);
create policy "users insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);
create policy "users update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- Auto-create a profile row when a user signs up (username comes from the
-- `data: {'username': ...}` metadata the app sends on sign-up). This makes
-- sign-up work even when email confirmation is enabled.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, username)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'username', 'Cinema Fan')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- watchlist / favorites (identical shape)
-- ---------------------------------------------------------------------------
create table if not exists public.watchlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  movie_id text not null,
  title text,
  genre text,
  year text,
  rating text,
  poster_url text,
  created_at timestamptz not null default now(),
  unique (user_id, movie_id)
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  movie_id text not null,
  title text,
  genre text,
  year text,
  rating text,
  poster_url text,
  created_at timestamptz not null default now(),
  unique (user_id, movie_id)
);

alter table public.watchlist enable row level security;
alter table public.favorites enable row level security;

create policy "watchlist is private"
  on public.watchlist for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "favorites are private"
  on public.favorites for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- reviews (user_id references profiles so PostgREST can embed
-- `profiles!inner(username)` as the app queries it)
-- ---------------------------------------------------------------------------
create table if not exists public.reviews (
  id text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  movie_id text not null,
  rating numeric not null default 0,
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

create policy "reviews are viewable by everyone"
  on public.reviews for select using (true);
create policy "users insert their own reviews"
  on public.reviews for insert with check (auth.uid() = user_id);
create policy "users delete their own reviews"
  on public.reviews for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- watch_history (composite PK so the app's upsert works without onConflict)
-- ---------------------------------------------------------------------------
create table if not exists public.watch_history (
  user_id uuid not null references auth.users (id) on delete cascade,
  movie_id text not null,
  progress double precision not null default 0,
  watched_at timestamptz not null default now(),
  primary key (user_id, movie_id)
);

alter table public.watch_history enable row level security;

create policy "watch history is private"
  on public.watch_history for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- messages (single community chat room; app supplies text ids/usernames)
-- Demo-friendly policies: anyone can read, signed-in or guest (anon role)
-- can post. Tighten the insert policy if you add per-user rooms.
-- ---------------------------------------------------------------------------
create table if not exists public.messages (
  id text primary key,
  user_id text not null,
  username text,
  content text not null,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "messages are viewable by everyone"
  on public.messages for select using (true);
create policy "anyone can post a message"
  on public.messages for insert with check (true);

-- ---------------------------------------------------------------------------
-- app_updates (managed via dashboard; app only reads the newest row)
-- ---------------------------------------------------------------------------
create table if not exists public.app_updates (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  build_number text,
  release_notes text,
  download_url text,
  is_mandatory boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.app_updates enable row level security;

create policy "app updates are viewable by everyone"
  on public.app_updates for select using (true);
-- (no insert/update/delete policies -> only the service role / dashboard
-- can write, which is what you want)

-- ---------------------------------------------------------------------------
-- Realtime: stream new chat messages to subscribed clients
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
