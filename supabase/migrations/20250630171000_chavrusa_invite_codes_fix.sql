-- Run this if 20250630170000 failed partway (FK error on chavrusa_members backfill).
-- Safe to re-run.

alter table public.chavrusa_invite_codes
  drop constraint if exists chavrusa_invite_codes_code_check;

alter table public.chavrusa_invite_codes
  add constraint chavrusa_invite_codes_code_check check (code ~ '^[0-9]{4,6}$');

insert into public.chavrusa_invite_codes (code, max_uses, note)
values ('261836', 999999, 'Beta launch code')
on conflict (code) do nothing;

insert into public.chavrusa_members (user_id, invite_code)
select cl.user_id, '261836'
from public.chavrusa_listings cl
on conflict (user_id) do nothing;

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
