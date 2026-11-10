-- VOW backend starter schema for Supabase PostgreSQL.
-- Review and test in a development project before production.
create extension if not exists pgcrypto;

create type public.vow_visibility as enum ('private','public');
create type public.vow_status as enum ('draft','pending','active','completed','cancelled','disputed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 60),
  created_at timestamptz not null default now()
);

create table public.vows (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique default ('VOW-' || upper(substr(encode(gen_random_bytes(6),'hex'),1,10))),
  creator_id uuid not null references auth.users(id),
  title text not null check (char_length(title) between 1 and 120),
  terms text not null check (char_length(terms) between 1 and 5000),
  agreement_type text not null check (agreement_type in ('mutual_pact','friendly_challenge','group_agreement','personal_commitment')),
  visibility public.vow_visibility not null default 'private',
  status public.vow_status not null default 'draft',
  deadline_at timestamptz,
  non_cash_stake text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vow_participants (
  vow_id uuid not null references public.vows(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'participant' check (role in ('creator','participant')),
  response text not null default 'invited' check (response in ('invited','accepted','declined')),
  responded_at timestamptz,
  primary key (vow_id,user_id)
);

create table public.vow_events (
  id bigint generated always as identity primary key,
  vow_id uuid not null references public.vows(id) on delete cascade,
  actor_id uuid not null references auth.users(id),
  event_type text not null check (event_type in ('created','terms_updated','invited','accepted','declined','activated','completed','cancelled','disputed')),
  event_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  created_by uuid not null references auth.users(id),
  is_private boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  joined_at timestamptz not null default now(),
  primary key(group_id,user_id)
);
create table public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.vows enable row level security;
alter table public.vow_participants enable row level security;
alter table public.vow_events enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_messages enable row level security;

-- Public VOWs are discoverable; private VOWs are visible only to creator/participants.
create policy "read public or involved vows" on public.vows for select to authenticated
using (
  visibility = 'public'
  or creator_id = auth.uid()
  or exists (select 1 from public.vow_participants p where p.vow_id = id and p.user_id = auth.uid())
);
create policy "creator creates vow" on public.vows for insert to authenticated
with check (creator_id = auth.uid());
create policy "creator updates own vow" on public.vows for update to authenticated
using (creator_id = auth.uid()) with check (creator_id = auth.uid());

create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "insert own profile" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "read own participation" on public.vow_participants for select to authenticated
using (user_id = auth.uid() or exists(select 1 from public.vows v where v.id = vow_id and v.creator_id = auth.uid()));
create policy "creator invites participants" on public.vow_participants for insert to authenticated
with check (exists(select 1 from public.vows v where v.id = vow_id and v.creator_id = auth.uid()));
create policy "participant responds" on public.vow_participants for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "participants read event history" on public.vow_events for select to authenticated
using (exists(select 1 from public.vows v where v.id = vow_id and (v.creator_id = auth.uid() or v.visibility = 'public'))
or exists(select 1 from public.vow_participants p where p.vow_id = vow_id and p.user_id = auth.uid()));
create policy "involved users append events" on public.vow_events for insert to authenticated
with check (actor_id = auth.uid() and exists(select 1 from public.vows v where v.id = vow_id and (v.creator_id = auth.uid() or exists(select 1 from public.vow_participants p where p.vow_id = vow_id and p.user_id = auth.uid()))));

create policy "group members read groups" on public.groups for select to authenticated
using (exists(select 1 from public.group_members m where m.group_id = id and m.user_id = auth.uid()));
create policy "authenticated create groups" on public.groups for insert to authenticated with check (created_by = auth.uid());
create policy "members read membership" on public.group_members for select to authenticated using (user_id = auth.uid());
create policy "group creator adds members" on public.group_members for insert to authenticated
with check (exists(select 1 from public.groups g where g.id = group_id and g.created_by = auth.uid()) or user_id = auth.uid());
create policy "members read messages" on public.group_messages for select to authenticated
using (exists(select 1 from public.group_members m where m.group_id = group_id and m.user_id = auth.uid()));
create policy "members send messages" on public.group_messages for insert to authenticated
with check (sender_id = auth.uid() and exists(select 1 from public.group_members m where m.group_id = group_id and m.user_id = auth.uid()));

-- IMPORTANT:
-- This is a starting schema, not a complete production security review.
-- Add server-side RPC/Edge Functions for invitation acceptance, event validation,
-- status transitions, immutable/versioned terms, notifications and moderation.
-- Never expose the Supabase service_role key in browser code.
