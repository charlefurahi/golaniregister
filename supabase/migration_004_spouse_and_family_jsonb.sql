-- Migration 004: spouse + family_members jsonb columns
--
-- SAFE TO RUN on your existing Supabase project — it only ADDS columns
-- with default values, it never drops or rewrites existing data.
-- Run this once in the Supabase SQL Editor, AFTER schema.sql and
-- migration_002_extended_member_info.sql.
--
-- Why this is needed: AdminDashboard.vue's saveResident() writes a
-- `spouse` object and a `family_members` array on every insert/update,
-- but neither schema.sql nor migration_002 ever created those columns
-- on public.residents (only the old `spouse_name` text column and the
-- `children` jsonb column exist). Without this migration, every save
-- fails with an error like:
--   "Could not find the 'spouse' column of 'residents' in the schema cache"
--
-- IMPORTANT: do NOT run migration_003_family_members.sql or
-- schema_v3_members.sql — those set up a different, incompatible
-- `members` / `households` table structure with its own RPC functions
-- (register_family, update_member_with_family) that the current
-- AdminDashboard.vue does not call anywhere. migration_003 in particular
-- RENAMES public.residents to public.members, which would break every
-- query this app makes (it queries `residents` directly). If you have
-- already run migration_003 against your live database, tell me before
-- running anything else — the fix is different in that case.

alter table public.residents
  add column if not exists spouse jsonb,
  add column if not exists family_members jsonb not null default '[]'::jsonb;
