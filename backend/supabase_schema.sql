-- ============================================================
-- IRV Voting App - Supabase Database Schema
-- Run this in the Supabase SQL editor
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ============================================================
-- ROOMS TABLE
-- ============================================================
create table if not exists public.rooms (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  code        text unique not null,
  createdby   uuid references auth.users on delete set null,
  isopen      boolean default true,
  createdat   timestamp with time zone default now()
);

-- Index for fast code lookups
create index if not exists rooms_code_idx on public.rooms(code);
create index if not exists rooms_createdby_idx on public.rooms(createdby);

-- ============================================================
-- OPTIONS TABLE
-- ============================================================
create table if not exists public.options (
  id        uuid primary key default gen_random_uuid(),
  roomid    uuid references public.rooms(id) on delete cascade,
  label     text not null,
  position  int not null default 0
);

create index if not exists options_roomid_idx on public.options(roomid);

-- ============================================================
-- BALLOTS TABLE
-- ============================================================
create table if not exists public.ballots (
  id            uuid primary key default gen_random_uuid(),
  roomid        uuid references public.rooms(id) on delete cascade,
  userid        uuid references auth.users on delete cascade,
  rankings      jsonb not null,  -- ordered array of option IDs: ["id-a", "id-c", "id-b"]
  submittedat   timestamp with time zone default now(),
  -- Prevent duplicate submissions
  unique(roomid, userid)
);

create index if not exists ballots_roomid_idx on public.ballots(roomid);
create index if not exists ballots_userid_idx on public.ballots(userid);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table public.rooms   enable row level security;
alter table public.options enable row level security;
alter table public.ballots enable row level security;

-- ROOMS policies
create policy "Anyone can view rooms"
  on public.rooms for select
  using (true);

create policy "Authenticated users can create rooms"
  on public.rooms for insert
  with check (auth.uid() = createdby);

create policy "Only creator can update room"
  on public.rooms for update
  using (auth.uid() = createdby);

-- OPTIONS policies
create policy "Anyone can view options"
  on public.options for select
  using (true);

create policy "Room creator can manage options"
  on public.options for insert
  with check (
    exists (
      select 1 from public.rooms
      where id = roomid and createdby = auth.uid()
    )
  );

-- BALLOTS policies
create policy "Users can view their own ballots"
  on public.ballots for select
  using (auth.uid() = userid);

create policy "Room creator can view all ballots in their room"
  on public.ballots for select
  using (
    exists (
      select 1 from public.rooms
      where id = roomid and createdby = auth.uid()
    )
  );

create policy "Authenticated users can submit one ballot per room"
  on public.ballots for insert
  with check (auth.uid() = userid);

-- ============================================================
-- HELPFUL FUNCTIONS
-- ============================================================

-- Function to get vote count for a room
create or replace function public.get_vote_count(room_id uuid)
returns bigint
language sql
security definer
as $$
  select count(*) from public.ballots where roomid = room_id;
$$;

-- ============================================================
-- ENABLE ANONYMOUS AUTH
-- ============================================================
-- Go to Authentication > Providers > Anonymous in Supabase dashboard
-- and enable "Allow anonymous sign-ins"
-- 
-- This allows users without accounts to vote with a stable anonymous identity.
-- ============================================================