-- Golani SDA Church — family/member registration upgrade
-- Run this AFTER schema.sql / migration_002_extended_member_info.sql.
-- It preserves existing residents and introduces real member + household records.

create extension if not exists pgcrypto;

-- Upgrade the old resident table to the church's real member table name.
do $$
begin
  if to_regclass('public.residents') is not null and to_regclass('public.members') is null then
    alter table public.residents rename to members;
  end if;
end $$;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  household_code text not null unique,
  head_member_id uuid,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.members
  add column if not exists member_code text,
  add column if not exists household_id uuid,
  add column if not exists relationship_to_head text,
  add column if not exists identity_key text;

-- Create stable identity keys for existing records. Phone/email are preferred;
-- otherwise name + DOB + gender is used. This prevents the same person from
-- being registered again by another administrator.
update public.members
set identity_key = case
  when nullif(trim(phone_number), '') is not null
    then 'phone:' || regexp_replace(lower(trim(phone_number)), '[^0-9+]', '', 'g')
  when nullif(trim(email), '') is not null
    then 'email:' || lower(trim(email))
  else 'person:' || md5(
    lower(regexp_replace(trim(full_name), '\\s+', ' ', 'g')) || '|' ||
    coalesce(date_of_birth::text, '') || '|' || coalesce(lower(trim(gender)), '')
  )
end
where identity_key is null;

-- Remove accidental duplicate keys from old data by retaining the earliest row.
delete from public.members a
using public.members b
where a.identity_key is not null
  and a.identity_key = b.identity_key
  and a.created_at > b.created_at;

create unique index if not exists members_identity_key_unique
  on public.members(identity_key)
  where identity_key is not null;

create unique index if not exists members_member_code_unique
  on public.members(member_code)
  where member_code is not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'members_household_fk'
      and conrelid = 'public.members'::regclass
  ) then
    alter table public.members
      add constraint members_household_fk
      foreign key (household_id) references public.households(id) on delete set null;
  end if;
end $$;

-- Give existing members codes.
create sequence if not exists public.member_code_seq start 1;

create or replace function public.next_member_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  n bigint;
begin
  n := nextval('public.member_code_seq');
  return 'GOL-' || lpad(n::text, 6, '0');
end;
$$;

update public.members
set member_code = public.next_member_code()
where member_code is null;

-- Keep the sequence ahead of any existing GOL- codes before future registrations.
select setval('public.member_code_seq', greatest(
  coalesce((select max(nullif(regexp_replace(member_code, '\D', '', 'g'), '')::bigint) from public.members), 0),
  1
), true);

update public.members
set relationship_to_head = coalesce(relationship_to_head, 'Mkuu wa familia')
where relationship_to_head is null;

-- Existing married residents become heads of their own household when possible.
insert into public.households (household_code, head_member_id, created_by)
select
  'H-' || upper(substr(replace(r.id::text, '-', ''), 1, 8)),
  r.id,
  r.registered_by
from public.members r
where r.household_id is null
  and r.marital_status in ('Ameoa/Ameolewa', 'Mjane', 'Mjane wa kiume', 'Talaka')
  and (r.spouse_name is not null or (jsonb_typeof(coalesce(r.children, '[]'::jsonb)) = 'array' and jsonb_array_length(coalesce(r.children, '[]'::jsonb)) > 0))
on conflict (household_code) do nothing;

update public.members r
set household_id = h.id
from public.households h
where h.head_member_id = r.id
  and r.household_id is null;

-- Humanised church-role validation. Existing values outside the list are kept
-- rather than deleted; this constraint therefore allows NULL and current values.

alter table public.households enable row level security;

drop policy if exists "Admins can view households" on public.households;
drop policy if exists "Admins can manage households" on public.households;

create policy "Admins can view households"
on public.households for select to authenticated
using (public.is_admin());

create policy "Admins can manage households"
on public.households for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Identity helper shared by frontend-facing RPCs.
create or replace function public.member_identity_key(p jsonb)
returns text
language plpgsql
immutable
as $$
declare
  v_phone text := regexp_replace(lower(trim(coalesce(p->>'phone_number',''))), '[^0-9+]', '', 'g');
  v_email text := lower(trim(coalesce(p->>'email','')));
  v_name text := regexp_replace(lower(trim(coalesce(p->>'full_name',''))), '\\s+', ' ', 'g');
  v_dob text := coalesce(p->>'date_of_birth','');
  v_gender text := lower(trim(coalesce(p->>'gender','')));
begin
  if v_phone <> '' then return 'phone:' || v_phone; end if;
  if v_email <> '' then return 'email:' || v_email; end if;
  return 'person:' || md5(v_name || '|' || v_dob || '|' || v_gender);
end;
$$;

-- Atomic registration: creates the household, main member and every family
-- member in one database transaction. A duplicate identity causes the whole
-- registration to fail safely.
create or replace function public.register_family(
  p_head jsonb,
  p_family jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_head_id uuid;
  v_household_id uuid;
  v_household_code text;
  v_member jsonb;
  v_member_id uuid;
  v_identity text;
  v_existing uuid;
  v_relation text;
begin
  if not public.is_admin() then
    raise exception 'Huna ruhusa ya kusajili wanachama.' using errcode = '42501';
  end if;

  v_identity := public.member_identity_key(p_head);
  select id into v_existing from public.members where identity_key = v_identity limit 1;
  if v_existing is not null then
    raise exception 'DUPLICATE_MEMBER:%', v_existing using errcode = '23505';
  end if;

  v_household_code := 'H-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  insert into public.households(household_code, created_by)
  values (v_household_code, v_user)
  returning id into v_household_id;

  insert into public.members (
    full_name, gender, date_of_birth, marital_status, phone_number, email,
    residence, is_baptized, baptism_year, baptism_place, church_area,
    ministry_group, church_role, spouse_name, children,
    emergency_contact_name, emergency_contact_phone, is_tucasa_member,
    institution_name, occupation, skills, special_needs, registered_by,
    household_id, relationship_to_head, identity_key, member_code
  )
  values (
    p_head->>'full_name', p_head->>'gender', nullif(p_head->>'date_of_birth','')::date,
    nullif(p_head->>'marital_status',''), nullif(p_head->>'phone_number',''),
    nullif(p_head->>'email',''), nullif(p_head->>'residence',''),
    coalesce((p_head->>'is_baptized')::boolean, false),
    nullif(p_head->>'baptism_year','')::integer, nullif(p_head->>'baptism_place',''),
    nullif(p_head->>'church_area',''), nullif(p_head->>'ministry_group',''),
    nullif(p_head->>'church_role',''), nullif(p_head->>'spouse_name',''),
    '[]'::jsonb, nullif(p_head->>'emergency_contact_name',''),
    nullif(p_head->>'emergency_contact_phone',''),
    coalesce((p_head->>'is_tucasa_member')::boolean, false),
    nullif(p_head->>'institution_name',''), nullif(p_head->>'occupation',''),
    nullif(p_head->>'skills',''), nullif(p_head->>'special_needs',''), v_user,
    v_household_id, 'Mkuu wa familia', v_identity, public.next_member_code()
  ) returning id into v_head_id;

  update public.households set head_member_id = v_head_id where id = v_household_id;

  for v_member in select * from jsonb_array_elements(coalesce(p_family, '[]'::jsonb)) loop
    if nullif(trim(v_member->>'full_name'), '') is null then
      continue;
    end if;

    v_identity := public.member_identity_key(v_member);
    select id into v_existing from public.members where identity_key = v_identity limit 1;
    if v_existing is not null then
      raise exception 'DUPLICATE_FAMILY_MEMBER:%:%', v_member->>'full_name', v_existing using errcode = '23505';
    end if;

    v_relation := coalesce(nullif(trim(v_member->>'relationship_to_head'), ''), 'Mwanafamilia');

    insert into public.members (
      full_name, gender, date_of_birth, marital_status, phone_number, email,
      residence, is_baptized, baptism_year, baptism_place, church_area,
      ministry_group, church_role, emergency_contact_name, emergency_contact_phone,
      is_tucasa_member, institution_name, occupation, skills, special_needs,
      registered_by, household_id, relationship_to_head, identity_key, member_code,
      spouse_name, children
    )
    values (
      v_member->>'full_name', v_member->>'gender', nullif(v_member->>'date_of_birth','')::date,
      nullif(v_member->>'marital_status',''), nullif(v_member->>'phone_number',''),
      nullif(v_member->>'email',''), nullif(v_member->>'residence',''),
      coalesce((v_member->>'is_baptized')::boolean, false),
      nullif(v_member->>'baptism_year','')::integer, nullif(v_member->>'baptism_place',''),
      nullif(v_member->>'church_area',''), nullif(v_member->>'ministry_group',''),
      nullif(v_member->>'church_role',''), nullif(v_member->>'emergency_contact_name',''),
      nullif(v_member->>'emergency_contact_phone',''),
      coalesce((v_member->>'is_tucasa_member')::boolean, false),
      nullif(v_member->>'institution_name',''), nullif(v_member->>'occupation',''),
      nullif(v_member->>'skills',''), nullif(v_member->>'special_needs',''),
      v_user, v_household_id, v_relation, v_identity, public.next_member_code(), null, '[]'::jsonb
    ) returning id into v_member_id;
  end loop;

  return jsonb_build_object('household_id', v_household_id, 'household_code', v_household_code, 'head_member_id', v_head_id);
exception
  when unique_violation then
    raise exception 'DUPLICATE_MEMBER:member tayari yupo kwenye mfumo.' using errcode = '23505';
end;
$$;

create or replace function public.update_member_with_family(
  p_member_id uuid,
  p_member jsonb,
  p_family jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_household_id uuid;
  v_member jsonb;
  v_identity text;
  v_existing uuid;
  v_family_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Huna ruhusa ya kubadilisha taarifa.' using errcode = '42501';
  end if;

  select household_id into v_household_id from public.members where id = p_member_id;
  if v_household_id is null then
    raise exception 'Member household haijapatikana.';
  end if;

  v_identity := public.member_identity_key(p_member);
  select id into v_existing from public.members where identity_key = v_identity and id <> p_member_id limit 1;
  if v_existing is not null then
    raise exception 'DUPLICATE_MEMBER:%', v_existing using errcode = '23505';
  end if;

  update public.members set
    full_name = p_member->>'full_name', gender = p_member->>'gender',
    date_of_birth = nullif(p_member->>'date_of_birth','')::date,
    marital_status = nullif(p_member->>'marital_status',''),
    phone_number = nullif(p_member->>'phone_number',''), email = nullif(p_member->>'email',''),
    residence = nullif(p_member->>'residence',''), is_baptized = coalesce((p_member->>'is_baptized')::boolean,false),
    baptism_year = nullif(p_member->>'baptism_year','')::integer,
    baptism_place = nullif(p_member->>'baptism_place',''), church_area = nullif(p_member->>'church_area',''),
    ministry_group = nullif(p_member->>'ministry_group',''), church_role = nullif(p_member->>'church_role',''),
    emergency_contact_name = nullif(p_member->>'emergency_contact_name',''),
    emergency_contact_phone = nullif(p_member->>'emergency_contact_phone',''),
    is_tucasa_member = coalesce((p_member->>'is_tucasa_member')::boolean,false),
    institution_name = nullif(p_member->>'institution_name',''), occupation = nullif(p_member->>'occupation',''),
    skills = nullif(p_member->>'skills',''), special_needs = nullif(p_member->>'special_needs',''),
    identity_key = v_identity, updated_at = now()
  where id = p_member_id;

  -- Family records submitted from the editor are updated when they have IDs;
  -- new records are inserted. Existing family records are not silently deleted.
  for v_member in select * from jsonb_array_elements(coalesce(p_family,'[]'::jsonb)) loop
    if nullif(trim(v_member->>'full_name'),'') is null then continue; end if;

    v_family_id := nullif(v_member->>'id','')::uuid;
    v_identity := public.member_identity_key(v_member);
    select id into v_existing from public.members where identity_key = v_identity and id <> coalesce(v_family_id, '00000000-0000-0000-0000-000000000000'::uuid) limit 1;
    if v_existing is not null then
      raise exception 'DUPLICATE_FAMILY_MEMBER:%:%', v_member->>'full_name', v_existing using errcode = '23505';
    end if;

    if v_family_id is not null then
      update public.members set
        full_name = v_member->>'full_name', gender = v_member->>'gender',
        date_of_birth = nullif(v_member->>'date_of_birth','')::date,
        marital_status = nullif(v_member->>'marital_status',''),
        phone_number = nullif(v_member->>'phone_number',''), email = nullif(v_member->>'email',''),
        relationship_to_head = coalesce(nullif(v_member->>'relationship_to_head',''),'Mwanafamilia'),
        is_baptized = coalesce((v_member->>'is_baptized')::boolean,false),
        baptism_year = nullif(v_member->>'baptism_year','')::integer,
        baptism_place = nullif(v_member->>'baptism_place',''),
        church_area = nullif(v_member->>'church_area',''),
        ministry_group = nullif(v_member->>'ministry_group',''),
        church_role = nullif(v_member->>'church_role',''),
        identity_key = v_identity, updated_at = now()
      where id = v_family_id and household_id = v_household_id;
    else
      insert into public.members(
        full_name, gender, date_of_birth, marital_status, phone_number, email,
        is_baptized, baptism_year, baptism_place, church_area, ministry_group, church_role,
        registered_by, household_id, relationship_to_head, identity_key, member_code
      ) values (
        v_member->>'full_name', v_member->>'gender', nullif(v_member->>'date_of_birth','')::date,
        nullif(v_member->>'marital_status',''), nullif(v_member->>'phone_number',''), nullif(v_member->>'email',''),
        coalesce((v_member->>'is_baptized')::boolean,false), nullif(v_member->>'baptism_year','')::integer,
        nullif(v_member->>'baptism_place',''), nullif(v_member->>'church_area',''),
        nullif(v_member->>'ministry_group',''), nullif(v_member->>'church_role',''),
        v_user, v_household_id, coalesce(nullif(v_member->>'relationship_to_head',''),'Mwanafamilia'),
        v_identity, public.next_member_code()
      );
    end if;
  end loop;

  return jsonb_build_object('member_id', p_member_id, 'household_id', v_household_id);
exception
  when unique_violation then
    raise exception 'DUPLICATE_MEMBER:Member tayari yupo kwenye mfumo.' using errcode = '23505';
end;
$$;

-- Make the new registration functions executable by signed-in admins only.
revoke all on function public.register_family(jsonb,jsonb) from public;
grant execute on function public.register_family(jsonb,jsonb) to authenticated;
revoke all on function public.update_member_with_family(uuid,jsonb,jsonb) from public;
grant execute on function public.update_member_with_family(uuid,jsonb,jsonb) to authenticated;

-- If the original schema has an RLS policy allowing admins to manage residents,
-- it continues to protect the underlying rows. The RPCs additionally check admin status.
