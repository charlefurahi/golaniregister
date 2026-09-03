-- =========================================================
-- GOLANI SDA CHURCH — MASTER RECONCILIATION
--
-- LENGO: kuhakikisha DB live inafikia hali SAHIHI inayolingana
-- na App.vue / AdminDashboard.vue / MemberProfileView.vue /
-- LoginView.vue zilizoko kwenye repo SASA HIVI — bila kujali
-- ni faili gani kati ya zilizopita ulizokwisha kukimbiza, kwa
-- mpangilio gani, au mara ngapi.
--
-- KILA amri hapa chini ni salama kurudia (idempotent):
--   IF EXISTS / IF NOT EXISTS / CREATE OR REPLACE kila mahali.
-- Hakuna DROP TABLE. Hakuna kupoteza data. Salama kukimbiza
-- mara nyingi tena baadaye pia.
--
-- Run kama block MOJA kwenye Supabase SQL Editor.
-- =========================================================


-- =========================================================
-- 1. EXTENSIONS
-- =========================================================
create extension if not exists pgcrypto;


-- =========================================================
-- 2. admin_users TABLE
-- =========================================================
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;


-- =========================================================
-- 3. residents TABLE — ADD ANY MISSING COLUMNS
--
-- Table lazima iwepo tayari (ina data). Hii HAIGUSI DATA
-- ILIYOPO — inaongeza tu columns ambazo bado hazipo.
-- =========================================================
alter table public.residents
  add column if not exists date_of_birth date,
  add column if not exists email text,
  add column if not exists baptism_year integer,
  add column if not exists baptism_place text,
  add column if not exists ministry_group text,
  add column if not exists church_role text,
  add column if not exists spouse_name text,
  add column if not exists spouse jsonb,
  add column if not exists children jsonb not null default '[]'::jsonb,
  add column if not exists family_members jsonb not null default '[]'::jsonb,
  add column if not exists emergency_contact_name text,
  add column if not exists emergency_contact_phone text,
  add column if not exists institution_name text,
  add column if not exists occupation text,
  add column if not exists skills text,
  add column if not exists special_needs text,
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists is_self_registered boolean not null default false;

-- phone_number MUST stay nullable — register_public_member() /
-- MemberProfileView.vue / AdminDashboard.vue all allow saving a
-- resident without a phone number. If an earlier script (the
-- "document 6" style full rebuild) left this NOT NULL, that would
-- silently break real saves. Safe no-op if already nullable.
alter table public.residents alter column phone_number drop not null;

-- full_name / gender must stay required — every RPC and both admin
-- and member forms enforce these before they will even submit.
alter table public.residents alter column full_name set not null;
alter table public.residents alter column gender set not null;

-- One Supabase Auth account can own at most one resident row
-- (multiple NULLs allowed — admin-created / guest rows have none).
drop index if exists residents_user_id_key;
create unique index residents_user_id_key
  on public.residents (user_id)
  where user_id is not null;

-- Drop the old (full_name, phone_number) hard-unique constraint if
-- present. The app already does its own, smarter duplicate matching
-- in three places (AdminDashboard.vue's findDuplicateMember/isSamePerson,
-- and register_public_member()'s phone+email / name+phone / name+dob
-- checks) — a blunt DB-level unique constraint on top of that would
-- throw a raw, unhandled Postgres error the moment two different
-- people share a name+phone combination (e.g. two family members
-- registered against the same household phone), which is a real
-- case this church's data has. Removing it does not weaken duplicate
-- protection; the app-level checks stay in force.
alter table public.residents drop constraint if exists residents_full_name_phone_unique;

-- Keep these two validation constraints, refreshed to the version
-- that matches the current forms (dynamic year ceiling, 4 church_role
-- options).
alter table public.residents drop constraint if exists residents_baptism_year_check;
alter table public.residents add constraint residents_baptism_year_check
  check (baptism_year is null or baptism_year between 1900 and extract(year from now())::int + 1);

alter table public.residents drop constraint if exists residents_church_role_check;
alter table public.residents add constraint residents_church_role_check
  check (church_role is null or church_role in ('Mshiriki', 'Kiongozi', 'Mchungaji', 'Mzee'));

-- Indexes used by admin search / lookups
create index if not exists residents_full_name_idx on public.residents(full_name);
create index if not exists residents_phone_number_idx on public.residents(phone_number);
create index if not exists residents_full_name_phone_idx on public.residents(full_name, phone_number);
create index if not exists residents_registered_by_idx on public.residents(registered_by);
create index if not exists residents_created_at_idx on public.residents(created_at);

alter table public.residents enable row level security;


-- =========================================================
-- 4. is_admin() — hardened, search_path pinned
-- =========================================================
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;


-- =========================================================
-- 5. admin_users POLICIES
-- =========================================================
drop policy if exists "Admins can view their own admin record" on public.admin_users;
drop policy if exists "Users can view their own admin record" on public.admin_users;
drop policy if exists "Admins can view admin users" on public.admin_users;
drop policy if exists "Admins can view all admin users" on public.admin_users;

create policy "Admins can view all admin users"
on public.admin_users
for select
to authenticated
using (public.is_admin());

create policy "Users can view their own admin record"
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());

-- Intentionally no insert/update/delete policy: admins are only
-- ever added manually in the SQL editor (see section 12 below).


-- =========================================================
-- 6. residents POLICIES — drop every name ever used across every
--    version of these files, then recreate the final set.
-- =========================================================
drop policy if exists "Authenticated admins can view residents" on public.residents;
drop policy if exists "Authenticated admins can register residents" on public.residents;
drop policy if exists "Authenticated admins can update residents" on public.residents;
drop policy if exists "Authenticated admins can delete residents" on public.residents;
drop policy if exists "Admins can view residents" on public.residents;
drop policy if exists "Admins can register residents" on public.residents;
drop policy if exists "Admins can update residents" on public.residents;
drop policy if exists "Admins can delete residents" on public.residents;
drop policy if exists "Members can view own profile" on public.residents;
drop policy if exists "Members can create own profile" on public.residents;
drop policy if exists "Members can update own profile" on public.residents;
drop policy if exists "Members can delete own profile" on public.residents;
drop policy if exists "Members can view own resident record" on public.residents;
drop policy if exists "Members can register own resident record" on public.residents;
drop policy if exists "Members can update own resident record" on public.residents;
-- The unguarded anon-insert policy from the earliest full-schema
-- draft — must NOT exist. It bypassed every duplicate check in
-- register_public_member()/check_name_duplicate().
drop policy if exists "Normal members can create residents" on public.residents;
drop policy if exists "Normal members can update residents" on public.residents;

-- ADMIN — full access
create policy "Admins can view residents"
on public.residents
for select
to authenticated
using (public.is_admin());

create policy "Admins can register residents"
on public.residents
for insert
to authenticated
with check (public.is_admin() and registered_by = auth.uid());

create policy "Admins can update residents"
on public.residents
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins can delete residents"
on public.residents
for delete
to authenticated
using (public.is_admin());

-- LOGGED-IN MEMBER (non-admin, own account) — own row only.
-- Not currently reachable from App.vue's UI (App.vue only ever
-- routes to guestMode), but MemberProfileView.vue's loadMyProfile()/
-- saveProfile() DO call this path when session is set, so this stays
-- wired up for when/if that flow is exposed.
create policy "Members can view own resident record"
on public.residents
for select
to authenticated
using (user_id = auth.uid());

create policy "Members can register own resident record"
on public.residents
for insert
to authenticated
with check (user_id = auth.uid() and registered_by = auth.uid());

create policy "Members can update own resident record"
on public.residents
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- No delete policy for members and no policy at all for anon —
-- guest (no-login) reads/writes go ONLY through the SECURITY DEFINER
-- RPCs in section 8, exactly as MemberProfileView.vue calls them.


-- =========================================================
-- 7. NORMALIZATION HELPERS (search_path pinned)
-- =========================================================
create or replace function public.normalize_phone(p text)
returns text
language sql
immutable
set search_path = public
as $$
  select regexp_replace(coalesce(p, ''), '\D', '', 'g');
$$;

create or replace function public.normalize_email(p text)
returns text
language sql
immutable
set search_path = public
as $$
  select lower(trim(coalesce(p, '')));
$$;

create or replace function public.normalize_name(p text)
returns text
language sql
immutable
set search_path = public
as $$
  select lower(regexp_replace(trim(coalesce(p, '')), '\s+', ' ', 'g'));
$$;


-- =========================================================
-- 8. GUEST SELF-SERVICE RPCs — matches MemberProfileView.vue exactly
-- =========================================================

-- 8a) lookup_public_member(phone, email) — used by
--     tryLoadExistingGuestRecord() to prefill the form.
create or replace function public.lookup_public_member(p_phone text, p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.residents;
begin
  if public.normalize_phone(p_phone) = '' or public.normalize_email(p_email) = '' then
    return null;
  end if;

  select * into v_row
  from public.residents
  where public.normalize_phone(phone_number) = public.normalize_phone(p_phone)
    and public.normalize_email(email) = public.normalize_email(p_email)
  limit 1;

  if not found then
    return null;
  end if;

  return to_jsonb(v_row);
end;
$$;

revoke all on function public.lookup_public_member(text, text) from public;
grant execute on function public.lookup_public_member(text, text) to anon, authenticated;

-- 8b) check_name_duplicate(full_name) — used by checkNameDuplicate()
--     while typing the name. Deliberately returns only a hint
--     (exists / count / last-2-digits of phone), never the full row.
create or replace function public.check_name_duplicate(p_full_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := public.normalize_name(p_full_name);
  v_count integer;
  v_phone text;
begin
  if v_name = '' then
    return jsonb_build_object('exists', false);
  end if;

  select count(*) into v_count
  from public.residents
  where public.normalize_name(full_name) = v_name;

  if v_count = 0 then
    return jsonb_build_object('exists', false);
  end if;

  select public.normalize_phone(phone_number) into v_phone
  from public.residents
  where public.normalize_name(full_name) = v_name
    and public.normalize_phone(phone_number) <> ''
  limit 1;

  return jsonb_build_object(
    'exists', true,
    'count', v_count,
    'phone_hint', case
      when v_phone is not null and length(v_phone) >= 2 then right(v_phone, 2)
      else null
    end
  );
end;
$$;

revoke all on function public.check_name_duplicate(text) from public;
grant execute on function public.check_name_duplicate(text) to anon, authenticated;

-- 8c) register_public_member(payload) — FINAL version (matches the
--     one migration_008 left live): matches an existing person by
--     phone+email, OR name+phone, OR name+date_of_birth, in that
--     order, and UPDATEs instead of duplicating. This is the version
--     saveProfile() in MemberProfileView.vue actually calls.
create or replace function public.register_public_member(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing_id uuid;
  v_row public.residents;
  v_was_update boolean := false;
  v_name text := public.normalize_name(p->>'full_name');
  v_phone text := public.normalize_phone(p->>'phone_number');
  v_email text := public.normalize_email(p->>'email');
  v_dob text := nullif(p->>'date_of_birth', '');
begin
  if nullif(trim(p->>'full_name'), '') is null then
    raise exception 'Jina langu kamili linahitajika.' using errcode = '22023';
  end if;
  if nullif(trim(p->>'gender'), '') is null then
    raise exception 'Jinsia yangu inahitajika.' using errcode = '22023';
  end if;

  -- (a) phone + email match exactly
  if v_phone <> '' and v_email <> '' then
    select id into v_existing_id
    from public.residents
    where public.normalize_phone(phone_number) = v_phone
      and public.normalize_email(email) = v_email
    limit 1;
  end if;

  -- (b) name + phone match (email may have changed/been mistyped)
  if v_existing_id is null and v_name <> '' and v_phone <> '' then
    select id into v_existing_id
    from public.residents
    where public.normalize_name(full_name) = v_name
      and public.normalize_phone(phone_number) = v_phone
    limit 1;
  end if;

  -- (c) name + date_of_birth match (phone may have changed)
  if v_existing_id is null and v_name <> '' and v_dob is not null then
    select id into v_existing_id
    from public.residents
    where public.normalize_name(full_name) = v_name
      and date_of_birth = v_dob::date
    limit 1;
  end if;

  if v_existing_id is not null then
    v_was_update := true;

    update public.residents set
      full_name = p->>'full_name',
      gender = p->>'gender',
      date_of_birth = nullif(p->>'date_of_birth','')::date,
      marital_status = nullif(p->>'marital_status',''),
      phone_number = nullif(p->>'phone_number',''),
      email = nullif(p->>'email',''),
      residence = nullif(p->>'residence',''),
      is_baptized = coalesce((p->>'is_baptized')::boolean, false),
      baptism_year = nullif(p->>'baptism_year','')::integer,
      baptism_place = nullif(p->>'baptism_place',''),
      church_area = nullif(p->>'church_area',''),
      ministry_group = nullif(p->>'ministry_group',''),
      church_role = nullif(p->>'church_role',''),
      spouse = p->'spouse',
      children = coalesce(p->'children', '[]'::jsonb),
      family_members = coalesce(p->'family_members', '[]'::jsonb),
      emergency_contact_name = nullif(p->>'emergency_contact_name',''),
      emergency_contact_phone = nullif(p->>'emergency_contact_phone',''),
      is_tucasa_member = coalesce((p->>'is_tucasa_member')::boolean, false),
      institution_name = nullif(p->>'institution_name',''),
      occupation = nullif(p->>'occupation',''),
      skills = nullif(p->>'skills',''),
      special_needs = nullif(p->>'special_needs','')
    where id = v_existing_id
    returning * into v_row;
  else
    insert into public.residents (
      full_name, gender, date_of_birth, marital_status, phone_number, email,
      residence, is_baptized, baptism_year, baptism_place, church_area,
      ministry_group, church_role, spouse, children, family_members,
      emergency_contact_name, emergency_contact_phone, is_tucasa_member,
      institution_name, occupation, skills, special_needs, is_self_registered
    ) values (
      p->>'full_name', p->>'gender', nullif(p->>'date_of_birth','')::date,
      nullif(p->>'marital_status',''), nullif(p->>'phone_number',''),
      nullif(p->>'email',''), nullif(p->>'residence',''),
      coalesce((p->>'is_baptized')::boolean, false),
      nullif(p->>'baptism_year','')::integer, nullif(p->>'baptism_place',''),
      nullif(p->>'church_area',''), nullif(p->>'ministry_group',''),
      nullif(p->>'church_role',''), p->'spouse',
      coalesce(p->'children', '[]'::jsonb), coalesce(p->'family_members', '[]'::jsonb),
      nullif(p->>'emergency_contact_name',''), nullif(p->>'emergency_contact_phone',''),
      coalesce((p->>'is_tucasa_member')::boolean, false),
      nullif(p->>'institution_name',''), nullif(p->>'occupation',''),
      nullif(p->>'skills',''), nullif(p->>'special_needs',''), true
    )
    returning * into v_row;
  end if;

  return jsonb_build_object('id', v_row.id, 'was_update', v_was_update);
end;
$$;

revoke all on function public.register_public_member(jsonb) from public;
grant execute on function public.register_public_member(jsonb) to anon, authenticated;


-- =========================================================
-- 9. LEGACY / UNUSED RPCs — remove
--
-- find_resident_profile() and update_normal_member_profile() were
-- an earlier self-service design (name+phone as the only identity
-- check) that MemberProfileView.vue does NOT call anymore — it was
-- replaced by lookup_public_member/check_name_duplicate/
-- register_public_member above. Leaving them behind means anon still
-- has a second, weaker write path into residents that skips the
-- newer duplicate protection. Safe to drop: nothing in the current
-- frontend references them.
-- =========================================================
drop function if exists public.find_resident_profile(text, text);
drop function if exists public.update_normal_member_profile(uuid, text, text, jsonb);


-- =========================================================
-- 10. updated_at TRIGGER
-- =========================================================
create or replace function public.update_residents_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists residents_updated_at on public.residents;
create trigger residents_updated_at
before update on public.residents
for each row
execute function public.update_residents_updated_at();


-- =========================================================
-- 11. CHANGE HISTORY (audit trail) — additive, admin-read-only
-- =========================================================
create table if not exists public.resident_change_history (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.residents(id) on delete cascade,
  field_name text not null,
  old_value jsonb,
  new_value jsonb,
  change_type text not null check (change_type in ('INSERT', 'UPDATE')),
  -- NULL = came from the public self-service form (anon/guest)
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now()
);

create index if not exists resident_change_history_resident_idx on public.resident_change_history(resident_id);
create index if not exists resident_change_history_field_idx on public.resident_change_history(field_name);
create index if not exists resident_change_history_changed_at_idx on public.resident_change_history(changed_at desc);

alter table public.resident_change_history enable row level security;

drop policy if exists "Admins can view resident history" on public.resident_change_history;
create policy "Admins can view resident history"
on public.resident_change_history
for select
to authenticated
using (public.is_admin());

create or replace function public.track_resident_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  column_name text;
  old_json jsonb;
  new_json jsonb;
begin
  if tg_op = 'INSERT' then
    insert into public.resident_change_history (resident_id, field_name, old_value, new_value, change_type, changed_by)
    values (new.id, 'PROFILE_CREATED', null, to_jsonb(new), 'INSERT', auth.uid());
    return new;
  end if;

  if tg_op = 'UPDATE' then
    for column_name in select key from jsonb_each(to_jsonb(new)) loop
      if column_name in ('id', 'created_at', 'updated_at') then
        continue;
      end if;

      old_json := to_jsonb(old) -> column_name;
      new_json := to_jsonb(new) -> column_name;

      if old_json is distinct from new_json then
        insert into public.resident_change_history (resident_id, field_name, old_value, new_value, change_type, changed_by)
        values (new.id, column_name, old_json, new_json, 'UPDATE', auth.uid());
      end if;
    end loop;
  end if;

  return new;
end;
$$;

drop trigger if exists residents_change_history on public.residents;
create trigger residents_change_history
after insert or update on public.residents
for each row
execute function public.track_resident_changes();


-- =========================================================
-- 12. ADD ADMIN USERS
--
-- Confirmed legitimate admins (union of every admin-bootstrap
-- snippet seen so far). Uses a SELECT ... WHERE EXISTS pattern
-- instead of plain VALUES, so if one UUID does not (yet) exist in
-- auth.users, that one row is silently skipped instead of failing
-- the whole insert with a foreign-key error. Run
-- check_admin_uuids.sql afterwards to see who got skipped.
-- =========================================================
insert into public.admin_users (user_id)
select candidate.user_id
from (values
  ('db574d80-538b-4efb-9325-28f0bb698edc'::uuid),
  ('c7778d02-c5de-4e71-b212-c848101635f3'::uuid),
  ('bc29c850-b728-4706-9794-309fa69b8460'::uuid),
  ('683106ea-494d-46c9-8836-9f0ef52beb69'::uuid),
  ('44be2dfc-d902-4e31-8b5e-05252dbf5ec1'::uuid),
  ('e7e3003c-013c-4bd7-b801-797781fb5fff'::uuid)
) as candidate(user_id)
where exists (select 1 from auth.users u where u.id = candidate.user_id)
on conflict (user_id) do nothing;


-- =========================================================
-- DONE — verify with 000_verify_live_state.sql again after running.
-- =========================================================
