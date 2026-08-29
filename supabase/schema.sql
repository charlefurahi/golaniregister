-- Golani SDA Resident Admin database
-- Run this whole file in a fresh Supabase SQL Editor query.
-- If you already have a residents table with real data, DO NOT run this file.
-- Instead run migration_002_extended_member_info.sql, which only ADDS
-- columns and never touches existing rows.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

drop policy if exists "Admins can view their own admin record" on public.admin_users;
create policy "Admins can view their own admin record"
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());

create table if not exists public.residents (
  id uuid primary key default gen_random_uuid(),

  -- =====================================================
  -- 1. TAARIFA BINAFSI (Personal info)
  -- =====================================================
  full_name text not null,
  gender text not null check (gender in ('Mwanaume', 'Mwanamke')),
  date_of_birth date,
  marital_status text check (
    marital_status in (
      'Hajaoa/Hajaolewa',
      'Ameoa/Ameolewa',
      'Mjane',
      'Mjane wa kiume',
      'Talaka'
    )
  ),
  phone_number text,
  email text,
  residence text,

  -- =====================================================
  -- 2. TAARIFA ZA KIROHO / KANISA (Spiritual & church info)
  -- =====================================================
  is_baptized boolean not null default false,
  baptism_year integer check (
    baptism_year is null
    or (baptism_year between 1900 and extract(year from now())::int + 1)
  ),
  baptism_place text,
  church_area text,
  ministry_group text,
  church_role text check (
    church_role is null
    or church_role in ('Mshiriki', 'Kiongozi', 'Mchungaji', 'Mzee')
  ),

  -- =====================================================
  -- 3. TAARIFA ZA FAMILIA (Family info - only relevant when married)
  -- =====================================================
  spouse_name text,
  children jsonb not null default '[]'::jsonb, -- [{ "name": "...", "age": 7 }, ...]
  emergency_contact_name text,
  emergency_contact_phone text,

  -- =====================================================
  -- 4. TAARIFA ZA ZIADA (Additional info)
  -- =====================================================
  is_tucasa_member boolean not null default false,
  institution_name text, -- chuo, mfano: UDSM, NIT (only relevant when is_tucasa_member = true)
  occupation text,
  skills text, -- vipaji/mahususi
  special_needs text, -- mahitaji maalum

  -- =====================================================
  -- SYSTEM
  -- =====================================================
  registered_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.residents enable row level security;

-- Remove earlier broad policies if they exist.
drop policy if exists "Authenticated admins can view residents" on public.residents;
drop policy if exists "Authenticated admins can register residents" on public.residents;
drop policy if exists "Authenticated admins can update residents" on public.residents;
drop policy if exists "Authenticated admins can delete residents" on public.residents;
drop policy if exists "Admins can view residents" on public.residents;
drop policy if exists "Admins can register residents" on public.residents;
drop policy if exists "Admins can update residents" on public.residents;
drop policy if exists "Admins can delete residents" on public.residents;

-- Helper function: only users listed in admin_users are admins.
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

create policy "Admins can view residents"
on public.residents
for select
to authenticated
using (public.is_admin());

create policy "Admins can register residents"
on public.residents
for insert
to authenticated
with check (
  public.is_admin()
  and registered_by = auth.uid()
);

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

create or replace function public.update_residents_updated_at()
returns trigger
language plpgsql
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

-- IMPORTANT:
-- After creating an Auth user, add that user's UUID here:
-- insert into public.admin_users (user_id)
-- values ('PASTE-AUTH-USER-UUID-HERE');
