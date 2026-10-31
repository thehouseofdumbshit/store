-- The House of Dumb S#iT: patronage platform prototype
-- Run in Supabase SQL Editor. Browser code uses anon/publishable key only.
create extension if not exists pgcrypto;

create table if not exists public.artists (
 id uuid primary key default gen_random_uuid(),
 user_id uuid unique references auth.users(id) on delete set null,
 display_name text not null,
 slug text unique not null,
 practice text not null default '',
 location text not null default '',
 tagline text not null default '',
 bio text not null default '',
 avatar_url text,
 published boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.artist_links (
 id uuid primary key default gen_random_uuid(),
 artist_id uuid not null references public.artists(id) on delete cascade,
 label text not null,
 url text not null,
 sort_order integer not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.commission_requests (
 id uuid primary key default gen_random_uuid(),
 patron_name text not null,
 email text not null,
 idea text not null,
 medium text not null default '',
 artist_name text not null default '',
 references_text text not null default '',
 status text not null default 'new',
 created_at timestamptz not null default now()
);
create table if not exists public.artist_suggestions (
 id uuid primary key default gen_random_uuid(),
 patron_name text not null default '',
 artist_name text not null,
 artist_url text not null default '',
 note text not null default '',
 created_at timestamptz not null default now()
);
create table if not exists public.patron_references (
 id uuid primary key default gen_random_uuid(),
 patron_name text not null default '',
 title text not null,
 category text not null default 'inspiration',
 url text not null,
 note text not null default '',
 created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists artists_set_updated_at on public.artists;
create trigger artists_set_updated_at before update on public.artists for each row execute function public.set_updated_at();

alter table public.artists enable row level security;
alter table public.artist_links enable row level security;
alter table public.commission_requests enable row level security;
alter table public.artist_suggestions enable row level security;
alter table public.patron_references enable row level security;

-- Public sees only published artist identity/profile links. No artwork table exists.
drop policy if exists "Public reads published artists" on public.artists;
create policy "Public reads published artists" on public.artists for select to anon, authenticated using (published = true or user_id = auth.uid());
drop policy if exists "Artist manages own profile" on public.artists;
create policy "Artist manages own profile" on public.artists for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "Public reads links for published artists" on public.artist_links;
create policy "Public reads links for published artists" on public.artist_links for select to anon, authenticated using (exists(select 1 from public.artists a where a.id=artist_id and (a.published=true or a.user_id=auth.uid())));
drop policy if exists "Artist manages own links" on public.artist_links;
create policy "Artist manages own links" on public.artist_links for all to authenticated using (exists(select 1 from public.artists a where a.id=artist_id and a.user_id=auth.uid())) with check (exists(select 1 from public.artists a where a.id=artist_id and a.user_id=auth.uid()));

-- Public submissions are permitted; reading these records is reserved for House staff.
drop policy if exists "Anyone can submit commission enquiry" on public.commission_requests;
create policy "Anyone can submit commission enquiry" on public.commission_requests for insert to anon, authenticated with check (true);
drop policy if exists "Anyone can suggest an artist" on public.artist_suggestions;
create policy "Anyone can suggest an artist" on public.artist_suggestions for insert to anon, authenticated with check (true);
drop policy if exists "Anyone can add patron reference" on public.patron_references;
create policy "Anyone can add patron reference" on public.patron_references for insert to anon, authenticated with check (true);

-- House staff access should be added via a separate staff allowlist and policies before production.
-- This prototype intentionally does not expose private enquiries/suggestions/references to anonymous visitors.
