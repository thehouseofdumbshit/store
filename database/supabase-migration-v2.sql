-- THE HOUSE OF DUMB S#iT — migration for artist and patron accounts + commissions
-- Run AFTER the existing supabase-schema.sql in Supabase SQL Editor.
-- Uses Supabase Auth UUIDs; never place service_role keys in browser code.

create extension if not exists pgcrypto;

-- Artist ownership is already represented by artists.user_id in the base schema.
create index if not exists artists_user_id_idx on public.artists(user_id);
create index if not exists artists_published_name_idx on public.artists(published, display_name);

-- Private patron account profile.
create table if not exists public.patron_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.patron_profiles enable row level security;
drop policy if exists "Patrons read own profile" on public.patron_profiles;
create policy "Patrons read own profile" on public.patron_profiles
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "Patrons create own profile" on public.patron_profiles;
create policy "Patrons create own profile" on public.patron_profiles
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "Patrons update own profile" on public.patron_profiles;
create policy "Patrons update own profile" on public.patron_profiles
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Link every commission to the authenticated patron and selected artist.
alter table public.commission_requests
  add column if not exists patron_user_id uuid references auth.users(id) on delete set null,
  add column if not exists artist_id uuid references public.artists(id) on delete set null;
create index if not exists commission_requests_patron_idx on public.commission_requests(patron_user_id, created_at desc);
create index if not exists commission_requests_artist_idx on public.commission_requests(artist_id, created_at desc);

-- Replace the prototype's anonymous/public insert policy. New commissions must be submitted
-- by a signed-in patron, and the selected artist must have a published profile.
drop policy if exists "Anyone can submit commission enquiry" on public.commission_requests;
drop policy if exists "Patrons submit own commission enquiries" on public.commission_requests;
create policy "Patrons submit own commission enquiries" on public.commission_requests
  for insert to authenticated
  with check (
    patron_user_id = auth.uid()
    and exists (
      select 1 from public.artists a
      where a.id = artist_id and a.published = true
    )
  );

-- Patrons can see only their own commission records.
drop policy if exists "Patrons read own commissions" on public.commission_requests;
create policy "Patrons read own commissions" on public.commission_requests
  for select to authenticated
  using (patron_user_id = auth.uid());

-- An artist can see commission requests addressed to their own artist profile.
drop policy if exists "Artists read commissions addressed to them" on public.commission_requests;
create policy "Artists read commissions addressed to them" on public.commission_requests
  for select to authenticated
  using (
    exists (
      select 1 from public.artists a
      where a.id = artist_id and a.user_id = auth.uid()
    )
  );

-- Artists can create their own profile after signing up.
drop policy if exists "Artist creates own profile" on public.artists;
create policy "Artist creates own profile" on public.artists
  for insert to authenticated with check (user_id = auth.uid());

-- Ensure the profile owner can update only their own artist record.
drop policy if exists "Artist updates own profile" on public.artists;
create policy "Artist updates own profile" on public.artists
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Existing base policy may already grant all operations to the owner; the explicit
-- insert/update policies above are retained for clarity and predictable onboarding.

-- Enable commission-request inserts on Realtime so an open artist dashboard can refresh
-- its notification list immediately. Safe to run if the table is already published.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'commission_requests'
     ) then
    alter publication supabase_realtime add table public.commission_requests;
  end if;
end $$;
