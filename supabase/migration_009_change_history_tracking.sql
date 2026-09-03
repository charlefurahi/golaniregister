-- =========================================================
-- Migration 009: Automatic change-history tracking
--
-- SAFE TO RUN on your existing Supabase project — this file does
-- NOT drop or alter public.residents in any way, and does NOT
-- touch user_id, is_self_registered, admin_users, is_admin(), or
-- any of the RPC functions the frontend already depends on
-- (lookup_public_member, check_name_duplicate, register_public_member).
--
-- WHY: keeps the self-service system (migration_005/006/008) fully
-- working exactly as-is, and simply adds a record of every change —
-- who changed what, from what value, to what value, and when —
-- for both admin edits AND normal-member (guest) self-service edits,
-- since the trigger fires no matter which path wrote the row.
--
-- Run this once in the Supabase SQL Editor. It's also safe to
-- re-run: every object below is created with IF NOT EXISTS / OR
-- REPLACE / DROP ... IF EXISTS first.
-- =========================================================


-- =========================================================
-- 1. HISTORY TABLE
-- =========================================================

create table if not exists public.resident_change_history (

  id uuid primary key default gen_random_uuid(),

  resident_id uuid not null
    references public.residents(id)
    on delete cascade,

  field_name text not null,

  old_value jsonb,
  new_value jsonb,

  change_type text not null
    check (change_type in ('INSERT', 'UPDATE')),

  -- NULL means the change came from the public self-service form
  -- (anon/guest), not a logged-in admin.
  changed_by uuid
    references auth.users(id)
    on delete set null,

  changed_at timestamptz not null default now()

);

create index if not exists resident_change_history_resident_idx
  on public.resident_change_history(resident_id);

create index if not exists resident_change_history_field_idx
  on public.resident_change_history(field_name);

create index if not exists resident_change_history_changed_at_idx
  on public.resident_change_history(changed_at desc);


-- =========================================================
-- 2. TRACKING FUNCTION
--
-- INSERT -> one row: 'PROFILE_CREATED', old_value = null,
--           new_value = the whole new row.
-- UPDATE -> one row per column that actually changed value,
--           skipping id/created_at/updated_at.
--
-- security definer so this can insert history rows even when the
-- write itself came from register_public_member() running as
-- anon/guest (anon has no direct grant on resident_change_history).
-- =========================================================

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

    insert into public.resident_change_history (
      resident_id, field_name, old_value, new_value, change_type, changed_by
    )
    values (
      new.id, 'PROFILE_CREATED', null, to_jsonb(new), 'INSERT', auth.uid()
    );

    return new;

  end if;

  if tg_op = 'UPDATE' then

    for column_name in
      select key from jsonb_each(to_jsonb(new))
    loop

      if column_name in ('id', 'created_at', 'updated_at') then
        continue;
      end if;

      old_json := to_jsonb(old) -> column_name;
      new_json := to_jsonb(new) -> column_name;

      if old_json is distinct from new_json then

        insert into public.resident_change_history (
          resident_id, field_name, old_value, new_value, change_type, changed_by
        )
        values (
          new.id, column_name, old_json, new_json, 'UPDATE', auth.uid()
        );

      end if;

    end loop;

  end if;

  return new;

end;
$$;


-- =========================================================
-- 3. TRIGGER
-- =========================================================

drop trigger if exists residents_change_history on public.residents;

create trigger residents_change_history
after insert or update
on public.residents
for each row
execute function public.track_resident_changes();


-- =========================================================
-- 4. RLS — admin-only read access
--
-- Normal members cannot read history directly (protects old
-- sensitive field values from being exposed to the public form).
-- =========================================================

alter table public.resident_change_history enable row level security;

drop policy if exists "Admins can view resident history" on public.resident_change_history;

create policy "Admins can view resident history"
on public.resident_change_history
for select
to authenticated
using (public.is_admin());

-- =========================================================
-- DONE. Nothing above touches public.residents' columns, its
-- existing RLS policies, or any RPC function — it only adds the
-- new history table + trigger on top of what's already working.
-- =========================================================