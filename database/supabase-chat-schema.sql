-- The House of Dumb S#iT — private commission chat
-- Apply in Supabase SQL editor after enabling Supabase Auth.
-- Create the four Auth users separately; insert their auth.users UUIDs into house_profiles.

create table if not exists public.house_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  role text not null check (role in ('artist','patron','concierge','super_admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.house_conversations (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  commission_reference text,
  status text not null default 'in_progress',
  created_at timestamptz not null default now()
);

create table if not exists public.house_conversation_members (
  conversation_id uuid not null references public.house_conversations(id) on delete cascade,
  profile_id uuid not null references public.house_profiles(id) on delete cascade,
  access_role text not null check (access_role in ('artist','patron','concierge','super_admin')),
  can_read boolean not null default true,
  can_write boolean not null default true,
  primary key (conversation_id, profile_id),
  constraint super_admin_read_only check (access_role <> 'super_admin' or can_write = false)
);

create table if not exists public.house_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.house_conversations(id) on delete cascade,
  sender_id uuid not null references public.house_profiles(id),
  body text not null check (length(trim(body)) > 0 and length(body) <= 10000),
  created_at timestamptz not null default now()
);
create index if not exists house_messages_conversation_created_idx
  on public.house_messages(conversation_id, created_at);

alter table public.house_profiles enable row level security;
alter table public.house_conversations enable row level security;
alter table public.house_conversation_members enable row level security;
alter table public.house_messages enable row level security;

-- Users can read their own profile. A separate, carefully scoped House staff policy
-- should be added if staff need to manage profile records from the application.
create policy "profile owner can read own profile"
  on public.house_profiles for select to authenticated
  using (id = auth.uid());

create policy "conversation members can read conversation"
  on public.house_conversations for select to authenticated
  using (exists (
    select 1 from public.house_conversation_members m
    where m.conversation_id = id and m.profile_id = auth.uid() and m.can_read
  ));

create policy "members can read membership list"
  on public.house_conversation_members for select to authenticated
  using (exists (
    select 1 from public.house_conversation_members mine
    where mine.conversation_id = conversation_id
      and mine.profile_id = auth.uid() and mine.can_read
  ));

create policy "conversation members can read messages"
  on public.house_messages for select to authenticated
  using (exists (
    select 1 from public.house_conversation_members m
    where m.conversation_id = house_messages.conversation_id
      and m.profile_id = auth.uid() and m.can_read
  ));

create policy "only writable members can send messages"
  on public.house_messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.house_conversation_members m
      join public.house_profiles p on p.id = m.profile_id
      where m.conversation_id = house_messages.conversation_id
        and m.profile_id = auth.uid()
        and m.can_read = true
        and m.can_write = true
        and p.role in ('artist','patron','concierge')
    )
  );

-- Intentionally no UPDATE/DELETE policies for messages: the chat is an auditable
-- conversation record. Add a separate correction/annotation workflow if needed.
-- Enable Realtime for public.house_messages in the Supabase dashboard to sync live.
