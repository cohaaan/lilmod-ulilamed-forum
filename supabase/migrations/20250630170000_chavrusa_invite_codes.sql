-- Chavrusas closed beta: numeric invite codes before new users can join.

create table if not exists public.chavrusa_settings (
  key text primary key,
  value jsonb not null
);

insert into public.chavrusa_settings (key, value)
values
  ('require_invite_code', 'true'::jsonb),
  ('member_invites_enabled', 'false'::jsonb)
on conflict (key) do nothing;

create table if not exists public.chavrusa_invite_codes (
  code text primary key check (code ~ '^[0-9]{4,6}$'),
  created_by uuid references auth.users (id) on delete set null,
  max_uses int not null default 1 check (max_uses > 0),
  uses_count int not null default 0 check (uses_count >= 0),
  note text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint chavrusa_invite_uses check (uses_count <= max_uses)
);

create index if not exists chavrusa_invite_codes_created_by_idx
  on public.chavrusa_invite_codes (created_by);

create table if not exists public.chavrusa_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  invite_code text not null references public.chavrusa_invite_codes (code),
  joined_at timestamptz not null default now()
);

-- Seed codes BEFORE any chavrusa_members rows (FK requires the code to exist).
insert into public.chavrusa_invite_codes (code, max_uses, note)
values
  ('261836', 999999, 'Beta launch code'),
  ('0000', 999999, 'Legacy backfill — not for distribution')
on conflict (code) do nothing;

-- Existing listing owners keep access.
insert into public.chavrusa_members (user_id, invite_code)
select cl.user_id, '261836'
from public.chavrusa_listings cl
on conflict (user_id) do nothing;

alter table public.chavrusa_settings enable row level security;
alter table public.chavrusa_invite_codes enable row level security;
alter table public.chavrusa_members enable row level security;

create policy chavrusa_settings_select_authenticated
  on public.chavrusa_settings
  for select
  to authenticated
  using (true);

create policy chavrusa_members_select_own
  on public.chavrusa_members
  for select
  to authenticated
  using (user_id = auth.uid());

create policy chavrusa_invite_codes_select_own
  on public.chavrusa_invite_codes
  for select
  to authenticated
  using (created_by = auth.uid());

create or replace function public.chavrusa_setting_bool(p_key text, p_default boolean)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select (value #>> '{}')::boolean from public.chavrusa_settings where key = p_key),
    p_default
  );
$$;

create or replace function public.is_chavrusa_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.chavrusa_members where user_id = auth.uid()
  );
$$;

create or replace function public.chavrusa_requires_invite()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.chavrusa_setting_bool('require_invite_code', true);
$$;

create or replace function public.validate_chavrusa_invite(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := trim(p_code);
  v_row public.chavrusa_invite_codes%rowtype;
begin
  if v_code !~ '^[0-9]{4,6}$' then
    return jsonb_build_object('valid', false, 'message', 'Enter your invite code');
  end if;

  if not public.chavrusa_requires_invite() then
    return jsonb_build_object('valid', true);
  end if;

  select * into v_row
  from public.chavrusa_invite_codes
  where code = v_code;

  if not found then
    return jsonb_build_object('valid', false, 'message', 'Invalid invite code');
  end if;

  if v_row.expires_at is not null and v_row.expires_at < now() then
    return jsonb_build_object('valid', false, 'message', 'This invite code has expired');
  end if;

  if v_row.uses_count >= v_row.max_uses then
    return jsonb_build_object('valid', false, 'message', 'This invite code has already been used');
  end if;

  return jsonb_build_object('valid', true);
end;
$$;

create or replace function public.redeem_chavrusa_invite(p_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := trim(p_code);
  v_check jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  if exists (select 1 from public.chavrusa_members where user_id = auth.uid()) then
    return;
  end if;

  if not public.chavrusa_requires_invite() then
    insert into public.chavrusa_members (user_id, invite_code)
    values (auth.uid(), coalesce(
      (select code from public.chavrusa_invite_codes where code = v_code),
      '261836'
    ))
    on conflict (user_id) do nothing;
    return;
  end if;

  v_check := public.validate_chavrusa_invite(v_code);
  if not (v_check ->> 'valid')::boolean then
    raise exception '%', coalesce(v_check ->> 'message', 'Invalid invite code');
  end if;

  update public.chavrusa_invite_codes
  set uses_count = uses_count + 1
  where code = v_code
    and uses_count < max_uses;

  if not found then
    raise exception 'This invite code has already been used';
  end if;

  insert into public.chavrusa_members (user_id, invite_code)
  values (auth.uid(), v_code);
end;
$$;

-- Phase 2: members can mint single-use codes when enabled in settings.
create or replace function public.create_chavrusa_invite()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_attempts int := 0;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;

  if not public.is_chavrusa_member() then
    raise exception 'Chavrusas members only';
  end if;

  if not public.chavrusa_setting_bool('member_invites_enabled', false) then
    raise exception 'Member invites are not enabled yet';
  end if;

  loop
    v_attempts := v_attempts + 1;
    if v_attempts > 50 then
      raise exception 'Could not generate a unique code';
    end if;

    v_code := lpad((floor(random() * 10000))::int::text, 4, '0');

    begin
      insert into public.chavrusa_invite_codes (code, created_by, max_uses, note)
      values (v_code, auth.uid(), 1, 'Member invite');
      return v_code;
    exception
      when unique_violation then
        continue;
    end;
  end loop;
end;
$$;

grant execute on function public.chavrusa_setting_bool(text, boolean) to anon, authenticated;
grant execute on function public.is_chavrusa_member() to authenticated;
grant execute on function public.chavrusa_requires_invite() to anon, authenticated;
grant execute on function public.validate_chavrusa_invite(text) to anon, authenticated;
grant execute on function public.redeem_chavrusa_invite(text) to authenticated;
grant execute on function public.create_chavrusa_invite() to authenticated;

-- Listings require Chavrusas membership.
drop policy if exists chavrusa_listings_select_authenticated on public.chavrusa_listings;
create policy chavrusa_listings_select_authenticated
  on public.chavrusa_listings
  for select
  to authenticated
  using (
    public.is_chavrusa_member()
    and (status = 'available' or user_id = auth.uid())
  );

drop policy if exists chavrusa_listings_insert_own on public.chavrusa_listings;
create policy chavrusa_listings_insert_own
  on public.chavrusa_listings
  for insert
  to authenticated
  with check (public.is_chavrusa_member() and user_id = auth.uid());

drop policy if exists chavrusa_listings_update_own on public.chavrusa_listings;
create policy chavrusa_listings_update_own
  on public.chavrusa_listings
  for update
  to authenticated
  using (public.is_chavrusa_member() and user_id = auth.uid())
  with check (public.is_chavrusa_member() and user_id = auth.uid());

drop policy if exists chavrusa_listings_delete_own on public.chavrusa_listings;
create policy chavrusa_listings_delete_own
  on public.chavrusa_listings
  for delete
  to authenticated
  using (public.is_chavrusa_member() and user_id = auth.uid());

drop policy if exists chavrusa_page_visits_insert_own on public.chavrusa_page_visits;
create policy chavrusa_page_visits_insert_own
  on public.chavrusa_page_visits
  for insert
  to authenticated
  with check (public.is_chavrusa_member() and user_id = auth.uid());
