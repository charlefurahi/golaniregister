-- =========================================================
-- DEPRECATED — DO NOT RUN
-- This restructures public.residents into members/households,
-- which AdminDashboard.vue / MemberProfileView.vue do NOT use.
-- Kept only for historical reference.
-- =========================================================

-- Golani SDA Church — fresh database schema for member + family registration.
-- Use this instead of schema.sql for a new Supabase project.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "Admins can view their own admin record" on public.admin_users;
create policy "Admins can view their own admin record" on public.admin_users
for select to authenticated using (user_id = auth.uid());

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  household_code text not null unique,
  head_member_id uuid,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  member_code text unique,
  household_id uuid references public.households(id) on delete set null,
  relationship_to_head text not null default 'Mkuu wa familia',
  identity_key text unique,

  full_name text not null,
  gender text not null check (gender in ('Mwanaume','Mwanamke')),
  date_of_birth date,
  marital_status text check (marital_status in ('Hajaoa/Hajaolewa','Ameoa/Ameolewa','Mjane','Mjane wa kiume','Talaka')),
  phone_number text,
  email text,
  residence text,

  is_baptized boolean not null default false,
  baptism_year integer,
  baptism_place text,
  church_area text,
  ministry_group text,
  church_role text,

  emergency_contact_name text,
  emergency_contact_phone text,

  is_tucasa_member boolean not null default false,
  institution_name text,
  occupation text,
  skills text,
  special_needs text,

  registered_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create sequence if not exists public.member_code_seq start 1;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admin_users where user_id=auth.uid());
$$;

alter table public.members enable row level security;
alter table public.households enable row level security;

drop policy if exists "Admins can view members" on public.members;
drop policy if exists "Admins can manage members" on public.members;
create policy "Admins can view members" on public.members for select to authenticated using (public.is_admin());
create policy "Admins can manage members" on public.members for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins can view households" on public.households;
drop policy if exists "Admins can manage households" on public.households;
create policy "Admins can view households" on public.households for select to authenticated using (public.is_admin());
create policy "Admins can manage households" on public.households for all to authenticated using (public.is_admin()) with check (public.is_admin());

create or replace function public.next_member_code()
returns text language plpgsql security definer set search_path=public as $$
begin
  return 'GOL-' || lpad(nextval('public.member_code_seq')::text, 6, '0');
end;
$$;

create or replace function public.member_identity_key(p jsonb)
returns text language plpgsql immutable as $$
declare
  v_phone text := regexp_replace(lower(trim(coalesce(p->>'phone_number',''))), '[^0-9+]', '', 'g');
  v_email text := lower(trim(coalesce(p->>'email','')));
  v_name text := regexp_replace(lower(trim(coalesce(p->>'full_name',''))), '\s+', ' ', 'g');
begin
  if v_phone <> '' then return 'phone:' || v_phone; end if;
  if v_email <> '' then return 'email:' || v_email; end if;
  return 'person:' || md5(v_name || '|' || coalesce(p->>'date_of_birth','') || '|' || lower(trim(coalesce(p->>'gender',''))));
end;
$$;

create or replace function public.update_members_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists members_updated_at on public.members;
create trigger members_updated_at before update on public.members for each row execute function public.update_members_updated_at();

-- Atomic create. A duplicate anywhere in the family rolls back the entire registration.
create or replace function public.register_family(p_head jsonb, p_family jsonb default '[]'::jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_user uuid := auth.uid(); v_household uuid; v_head uuid; v_item jsonb; v_key text; v_existing uuid; v_code text;
begin
  if not public.is_admin() then raise exception 'Huna ruhusa ya kusajili wanachama.' using errcode='42501'; end if;
  v_key := public.member_identity_key(p_head);
  select id into v_existing from public.members where identity_key=v_key;
  if v_existing is not null then raise exception 'DUPLICATE_MEMBER:%',v_existing using errcode='23505'; end if;

  v_code := 'H-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
  insert into public.households(household_code,created_by) values(v_code,v_user) returning id into v_household;

  insert into public.members(member_code,household_id,relationship_to_head,identity_key,full_name,gender,date_of_birth,marital_status,phone_number,email,residence,is_baptized,baptism_year,baptism_place,church_area,ministry_group,church_role,emergency_contact_name,emergency_contact_phone,is_tucasa_member,institution_name,occupation,skills,special_needs,registered_by)
  values(public.next_member_code(),v_household,'Mkuu wa familia',v_key,p_head->>'full_name',p_head->>'gender',nullif(p_head->>'date_of_birth','')::date,nullif(p_head->>'marital_status',''),nullif(p_head->>'phone_number',''),nullif(p_head->>'email',''),nullif(p_head->>'residence',''),coalesce((p_head->>'is_baptized')::boolean,false),nullif(p_head->>'baptism_year','')::int,nullif(p_head->>'baptism_place',''),nullif(p_head->>'church_area',''),nullif(p_head->>'ministry_group',''),nullif(p_head->>'church_role',''),nullif(p_head->>'emergency_contact_name',''),nullif(p_head->>'emergency_contact_phone',''),coalesce((p_head->>'is_tucasa_member')::boolean,false),nullif(p_head->>'institution_name',''),nullif(p_head->>'occupation',''),nullif(p_head->>'skills',''),nullif(p_head->>'special_needs',''),v_user) returning id into v_head;
  update public.households set head_member_id=v_head where id=v_household;

  for v_item in select * from jsonb_array_elements(coalesce(p_family,'[]'::jsonb)) loop
    if nullif(trim(v_item->>'full_name'),'') is null then continue; end if;
    v_key := public.member_identity_key(v_item);
    select id into v_existing from public.members where identity_key=v_key;
    if v_existing is not null then raise exception 'DUPLICATE_FAMILY_MEMBER:%',v_item->>'full_name' using errcode='23505'; end if;
    insert into public.members(member_code,household_id,relationship_to_head,identity_key,full_name,gender,date_of_birth,marital_status,phone_number,email,is_baptized,registered_by)
    values(public.next_member_code(),v_household,coalesce(nullif(v_item->>'relationship_to_head',''),'Mwanafamilia'),v_key,v_item->>'full_name',nullif(v_item->>'gender',''),nullif(v_item->>'date_of_birth','')::date,nullif(v_item->>'marital_status',''),nullif(v_item->>'phone_number',''),nullif(v_item->>'email',''),coalesce((v_item->>'is_baptized')::boolean,false),v_user);
  end loop;
  return jsonb_build_object('household_id',v_household,'household_code',v_code,'head_member_id',v_head);
exception when unique_violation then raise exception 'DUPLICATE_MEMBER:Member tayari yupo kwenye mfumo.' using errcode='23505';
end; $$;

grant execute on function public.register_family(jsonb,jsonb) to authenticated;
