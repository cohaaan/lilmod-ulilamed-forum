-- Run these ONE AT A TIME in Supabase SQL Editor if the full file crashes the dashboard.
-- Project: https://supabase.com/dashboard/project/lxcbaortmbhjsthycdkt/sql/new

-- STEP 1: tables
create table if not exists public.chavrusa_listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  display_name text not null,
  age int not null check (age >= 13 and age <= 120),
  learning_interests text not null,
  session_length text not null,
  topic text not null,
  availability text not null,
  phone text not null,
  ok_whatsapp boolean not null default false,
  ok_text boolean not null default false,
  ok_call boolean not null default false,
  preferred_contact text not null check (preferred_contact in ('whatsapp', 'text', 'call')),
  status text not null default 'available' check (status in ('available', 'matched', 'paused')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chavrusa_listings_user_unique unique (user_id),
  constraint chavrusa_listings_contact_methods check (
    ok_whatsapp or ok_text or ok_call
  )
);

create index if not exists chavrusa_listings_status_idx
  on public.chavrusa_listings (status, updated_at desc);

create table if not exists public.chavrusa_page_visits (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  visited_at timestamptz not null default now()
);

create index if not exists chavrusa_page_visits_user_day_idx
  on public.chavrusa_page_visits (user_id, ((visited_at at time zone 'UTC')::date));

-- STEP 2: updated_at trigger
create or replace function public.set_chavrusa_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists chavrusa_listings_updated_at on public.chavrusa_listings;
create trigger chavrusa_listings_updated_at
  before update on public.chavrusa_listings
  for each row
  execute function public.set_chavrusa_updated_at();

-- STEP 3: RLS
alter table public.chavrusa_listings enable row level security;
alter table public.chavrusa_page_visits enable row level security;

create policy chavrusa_listings_select_authenticated
  on public.chavrusa_listings
  for select
  to authenticated
  using (status = 'available' or user_id = auth.uid());

create policy chavrusa_listings_insert_own
  on public.chavrusa_listings
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy chavrusa_listings_update_own
  on public.chavrusa_listings
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy chavrusa_listings_delete_own
  on public.chavrusa_listings
  for delete
  to authenticated
  using (user_id = auth.uid());

create policy chavrusa_page_visits_insert_own
  on public.chavrusa_page_visits
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- STEP 4: visit counter RPC
create or replace function public.record_chavrusa_page_visit()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;

  insert into public.chavrusa_page_visits (user_id)
  select auth.uid()
  where not exists (
    select 1
    from public.chavrusa_page_visits
    where user_id = auth.uid()
      and visited_at::date = current_date
  );
end;
$$;

grant execute on function public.record_chavrusa_page_visit () to authenticated;

-- STEP 5: learning details (what to learn — pace, level, goal)
alter table public.chavrusa_listings
  add column if not exists learning_details text not null default '';
