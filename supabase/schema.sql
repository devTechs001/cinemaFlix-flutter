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

-- ---------------------------------------------------------------------------
-- movies catalogue (added with the unified-Movie update; safe to run
-- standalone if you already ran the schema above). The app reads this
-- table via MovieService and updates live through Realtime; when the
-- table is empty/missing it uses the bundled catalogue instead.
-- ---------------------------------------------------------------------------
create table if not exists public.movies (
  id text primary key,
  title text not null,
  year text,
  rating text,
  genre text,
  description text,
  "cast" text,
  director text,
  duration text,
  poster_url text,
  backdrop_url text,
  video_url text,
  created_at timestamptz not null default now()
);

alter table public.movies enable row level security;

create policy "movies are viewable by everyone"
  on public.movies for select using (true);
-- (writes: service role / dashboard only)

insert into public.movies
  (id, title, year, rating, genre, description, "cast", director, duration, poster_url, video_url)
values
  ('dune2', 'Dune: Part Two', '2024', '8.5', 'Sci-Fi / Adventure', 'Paul Atreides unites with the Fremen to seek revenge against those who destroyed his family. As he faces a choice between the love of his life and the fate of the universe, he must prevent a terrible future only he can foresee.', 'Timothee Chalamet, Zendaya, Rebecca Ferguson', 'Denis Villeneuve', '2h 46m', 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
  ('oppenheimer', 'Oppenheimer', '2023', '8.3', 'Drama / History', 'The story of J. Robert Oppenheimer and his pivotal role in the development of the atomic bomb during World War II. A gripping tale of ambition, morality and consequence.', 'Cillian Murphy, Emily Blunt, Matt Damon', 'Christopher Nolan', '3h 0m', 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
  ('batman', 'The Batman', '2022', '7.8', 'Action / Crime', 'When a sadistic serial killer targets key political figures in Gotham, Batman must investigate the city and its hidden corruption and question his own family legacy.', 'Robert Pattinson, Zoe Kravitz, Jeffrey Wright', 'Matt Reeves', '2h 56m', 'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'),
  ('deadpool3', 'Deadpool & Wolverine', '2024', '7.7', 'Action / Comedy', 'The merc with a mouth returns alongside Wolverine in a time-twisting adventure that rips the multiverse wide open. Expect chaos, cameos and fourth-wall demolitions.', 'Ryan Reynolds, Hugh Jackman, Emma Corrin', 'Shawn Levy', '2h 8m', 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'),
  ('furiosa', 'Furiosa: A Mad Max Saga', '2024', '7.6', 'Action / Sci-Fi', 'Snatched from the Green Place of Many Mothers, young Furiosa falls into the hands of warlord Dementus and his biker horde as she plots her path home across the Wasteland.', 'Anya Taylor-Joy, Chris Hemsworth, Tom Burke', 'George Miller', '2h 28m', 'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xceZprc.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4'),
  ('inception', 'Inception', '2010', '8.8', 'Sci-Fi / Thriller', 'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea into the mind of a CEO. The ultimate heist: inception.', 'Leonardo DiCaprio, Joseph Gordon-Levitt, Elliot Page', 'Christopher Nolan', '2h 28m', 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4'),
  ('interstellar', 'Interstellar', '2014', '8.7', 'Sci-Fi / Drama', 'When Earth becomes uninhabitable, a former NASA pilot leads a mission through a wormhole in search of a new home for humanity among distant galaxies.', 'Matthew McConaughey, Anne Hathaway, Jessica Chastain', 'Christopher Nolan', '2h 49m', 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'),
  ('joker', 'Joker', '2019', '8.4', 'Drama / Crime', 'A mentally troubled stand-up comedian embarks on a downward spiral that leads to the creation of an iconic villain. A gritty character study of a society that looks away.', 'Joaquin Phoenix, Robert De Niro, Zazie Beetz', 'Todd Phillips', '2h 2m', 'https://image.tmdb.org/t/p/w500/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4'),
  ('dark-knight', 'The Dark Knight', '2008', '9.0', 'Action / Crime', 'Batman raises the stakes in his war on crime, but the Joker, a criminal mastermind with a twisted smile, plunges Gotham into anarchy and forces him ever closer to crossing the line.', 'Christian Bale, Heath Ledger, Aaron Eckhart', 'Christopher Nolan', '2h 32m', 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
  ('pulp-fiction', 'Pulp Fiction', '1994', '8.9', 'Crime / Thriller', 'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption told out of order.', 'John Travolta, Samuel L. Jackson, Uma Thurman', 'Quentin Tarantino', '2h 34m', 'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4'),
  ('fight-club', 'Fight Club', '1999', '8.8', 'Drama', 'An insomniac office worker and a devil-may-care soap maker form an underground fight club that evolves into something far more dangerous.', 'Brad Pitt, Edward Norton, Helena Bonham Carter', 'David Fincher', '2h 19m', 'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
  ('matrix', 'The Matrix', '1999', '8.7', 'Sci-Fi / Action', 'A hacker discovers the shocking truth about his reality and his role in the war against its controllers, and must choose between comfortable illusion and brutal freedom.', 'Keanu Reeves, Laurence Fishburne, Carrie-Anne Moss', 'The Wachowskis', '2h 16m', 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4'),
  ('forrest-gump', 'Forrest Gump', '1994', '8.8', 'Drama / Romance', 'A kind-hearted man from Alabama unwittingly influences several defining historical events in 20th-century America while searching for his childhood love.', 'Tom Hanks, Robin Wright, Gary Sinise', 'Robert Zemeckis', '2h 22m', 'https://image.tmdb.org/t/p/w500/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4'),
  ('titanic', 'Titanic', '1997', '7.9', 'Romance / Drama', 'A seventeen-year-old aristocrat falls in love with a kind but poor artist aboard the luxurious, ill-fated R.M.S. Titanic.', 'Leonardo DiCaprio, Kate Winslet, Billy Zane', 'Cameron', '3h 14m', 'https://image.tmdb.org/t/p/w500/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'),
  ('endgame', 'Avengers: Endgame', '2019', '8.4', 'Action / Adventure', 'After the devastating events that wiped out half of all life, the remaining Avengers assemble once more to undo the snap and restore the universe.', 'Robert Downey Jr., Chris Evans, Mark Ruffalo', 'Anthony and Joe Russo', '3h 1m', 'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
  ('no-way-home', 'Spider-Man: No Way Home', '2021', '8.2', 'Action / Adventure', 'When a spell goes wrong, Peter Parker must face villains from every universe that knows Spider-Man and discover what it truly means to wear the mask.', 'Tom Holland, Zendaya, Benedict Cumberbatch', 'Jon Watts', '2h 28m', 'https://image.tmdb.org/t/p/w500/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'),
  ('avatar-2', 'Avatar: The Way of Water', '2022', '7.6', 'Sci-Fi / Adventure', 'Jake Sully and Neytiri have formed a family on Pandora. When an ancient threat resurfaces, they must fight a difficult war against the humans and protect what matters most.', 'Sam Worthington, Zoe Saldana, Sigourney Weaver', 'Cameron', '3h 12m', 'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
  ('john-wick-4', 'John Wick: Chapter 4', '2023', '7.7', 'Action / Thriller', 'With the price on his head ever increasing, John Wick uncovers a path to defeating the High Table. But before he can earn his freedom, he must face a new enemy across the globe.', 'Keanu Reeves, Donnie Yen, Bill Skarsgard', 'Chad Stahelski', '2h 49m', 'https://image.tmdb.org/t/p/w500/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4'),
  ('top-gun-maverick', 'Top Gun: Maverick', '2022', '8.3', 'Action / Drama', 'After more than thirty years of service, Pete Mitchell must confront the ghosts of his past when he trains a new squad of graduates for an impossible mission.', 'Tom Cruise, Miles Teller, Jennifer Connelly', 'Joseph Kosinski', '2h 10m', 'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4'),
  ('everything-everywhere', 'Everything Everywhere All at Once', '2022', '7.8', 'Sci-Fi / Comedy', 'An ageing Chinese immigrant is swept up in an insane adventure where she alone can save existence by exploring other universes and the lives she could have led.', 'Michelle Yeoh, Ke Huy Quan, Stephanie Hsu', 'Daniel Kwan, Daniel Scheinert', '2h 19m', 'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4')
on conflict (id) do nothing;

alter publication supabase_realtime add table public.movies;
