-- Migration 002: Extended member info
--
-- SAFE TO RUN on your existing Supabase project — it only ADDS columns
-- with default values, it never drops or rewrites existing data.
-- Run this once in the Supabase SQL Editor.

alter table public.residents
  add column if not exists email text,
  add column if not exists baptism_year integer,
  add column if not exists baptism_place text,
  add column if not exists ministry_group text,
  add column if not exists church_role text,
  add column if not exists spouse_name text,
  add column if not exists children jsonb not null default '[]'::jsonb,
  add column if not exists emergency_contact_name text,
  add column if not exists emergency_contact_phone text,
  add column if not exists institution_name text,
  add column if not exists skills text,
  add column if not exists special_needs text;

-- Validation constraints (dropped first so this migration can be re-run safely).
alter table public.residents drop constraint if exists residents_baptism_year_check;
alter table public.residents add constraint residents_baptism_year_check check (
  baptism_year is null
  or (baptism_year between 1900 and extract(year from now())::int + 1)
);

alter table public.residents drop constraint if exists residents_church_role_check;
alter table public.residents add constraint residents_church_role_check check (
  church_role is null
  or church_role in ('Mshiriki', 'Kiongozi', 'Mchungaji', 'Mzee')
);

-- No RLS policy changes needed — the existing is_admin() based policies
-- on public.residents already cover these new columns automatically.
