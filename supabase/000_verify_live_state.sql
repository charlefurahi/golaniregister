-- =========================================================
-- STEP 0: RUN THIS FIRST — READ ONLY, CHANGES NOTHING
--
-- Paste each result back so we can confirm exactly what is
-- live before running 999_reconcile_and_harden.sql.
-- =========================================================

-- 1) Columns currently on public.residents
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'residents'
order by ordinal_position;

-- 2) Constraints on public.residents (unique / check)
select conname, contype, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.residents'::regclass
order by conname;

-- 3) RLS policies currently on public.residents
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'residents'
order by policyname;

-- 4) RLS policies currently on public.admin_users
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'admin_users'
order by policyname;

-- 5) Which functions exist, who can execute them, and whether
--    search_path is pinned (empty proconfig = NOT hardened yet)
select p.proname, pg_get_function_identity_arguments(p.oid) as args,
       p.prosecdef as security_definer, p.proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'is_admin', 'normalize_phone', 'normalize_email', 'normalize_name',
    'lookup_public_member', 'check_name_duplicate', 'register_public_member',
    'find_resident_profile', 'update_normal_member_profile',
    'update_residents_updated_at', 'track_resident_changes'
  )
order by p.proname;

-- 6) How many admins are currently registered (and their emails)
select au.user_id, u.email, au.created_at
from public.admin_users au
left join auth.users u on u.id = au.user_id
order by au.created_at;

-- 7) Does resident_change_history exist yet?
select to_regclass('public.resident_change_history') as history_table_exists;
