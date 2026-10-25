-- The House of Dumb S#iT CMS schema for Supabase / PostgreSQL
-- Run this in Supabase Dashboard -> SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  artist text not null,
  price numeric(12,2) not null default 0 check (price >= 0),
  stock_quantity integer not null default 1 check (stock_quantity >= 0),
  edition text not null default '',
  image_url text,
  description text not null default '',
  bg text not null default '#d8d3c8',
  status_label text not null default 'Original',
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.site_content (
  key text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists site_content_set_updated_at on public.site_content;
create trigger site_content_set_updated_at before update on public.site_content
for each row execute function public.set_updated_at();

alter table public.admin_users enable row level security;
alter table public.products enable row level security;
alter table public.site_content enable row level security;

-- Admins can see their own allowlist row. Admin membership is assigned by project owner
-- from SQL Editor, not from the public website.
drop policy if exists "Admins can read own admin row" on public.admin_users;
create policy "Admins can read own admin row" on public.admin_users
for select to authenticated using (user_id = auth.uid());

drop policy if exists "Public can read published products" on public.products;
create policy "Public can read published products" on public.products
for select to anon, authenticated using (published = true or exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products" on public.products
for insert to authenticated with check (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products" on public.products
for update to authenticated using (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
)) with check (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products" on public.products
for delete to authenticated using (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Public can read site content" on public.site_content;
create policy "Public can read site content" on public.site_content
for select to anon, authenticated using (true);

drop policy if exists "Admins can insert site content" on public.site_content;
create policy "Admins can insert site content" on public.site_content
for insert to authenticated with check (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can update site content" on public.site_content;
create policy "Admins can update site content" on public.site_content
for update to authenticated using (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
)) with check (exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

-- Optional starter content. Safe to re-run.
insert into public.site_content(key,value) values
('hero_headline', E'Wear\\nyour own\\ndamn thing.'),
('hero_intro', 'We commission artists to make singular works you can live in. Not merch. Not another drop. Art with somewhere to go.'),
('house_statement', 'The House of Dumb S#iT brings artists and ideas together to make singular creative work. We question the prescribed, make room for contradiction, and leave enough space for things to be beautiful, strange, sincere or gloriously unnecessary.')
on conflict (key) do nothing;

-- After creating your user in Supabase Authentication -> Users, add their UUID:
-- insert into public.admin_users(user_id) values ('YOUR_AUTH_USER_UUID');
