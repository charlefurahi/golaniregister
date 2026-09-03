-- =========================================================
-- COLUMN: LINK A RESIDENT ROW TO ITS OWN AUTH ACCOUNT
--
-- Nullable — admin-created rows won't have one, self-registered
-- members will. A unique index (partial, ignores nulls) makes
-- sure one account can only ever own one resident row.
-- =========================================================
alter table public.residents
  add column if not exists user_id uuid references auth.users(id) on delete set null;

drop index if exists residents_user_id_key;
create unique index residents_user_id_key
  on public.residents (user_id)
  where user_id is not null;

-- =========================================================
-- REMOVE OLD RESIDENTS POLICIES
-- =========================================================
drop policy if exists "Authenticated admins can view residents" on public.residents;
drop policy if exists "Authenticated admins can register residents" on public.residents;
drop policy if exists "Authenticated admins can update residents" on public.residents;
drop policy if exists "Authenticated admins can delete residents" on public.residents;
drop policy if exists "Admins can view residents" on public.residents;
drop policy if exists "Admins can register residents" on public.residents;
drop policy if exists "Admins can update residents" on public.residents;
drop policy if exists "Admins can delete residents" on public.residents;

-- Remove old member (self-service) policies too, so this file can be re-run safely
drop policy if exists "Members can view own resident record" on public.residents;
drop policy if exists "Members can register own resident record" on public.residents;
drop policy if exists "Members can update own resident record" on public.residents;

-- =========================================================
-- FUNCTION: CHECK WHETHER LOGGED-IN USER IS AN ADMIN
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

-- =========================================================
-- VIEW RESIDENTS (ADMIN — sees every resident)
-- =========================================================
create policy "Admins can view residents"
on public.residents
for select
to authenticated
using (public.is_admin());

-- =========================================================
-- REGISTER RESIDENTS (ADMIN)
-- =========================================================
create policy "Admins can register residents"
on public.residents
for insert
to authenticated
with check (
  public.is_admin()
  and registered_by = auth.uid()
);

-- =========================================================
-- UPDATE RESIDENTS (ADMIN)
-- =========================================================
create policy "Admins can update residents"
on public.residents
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- =========================================================
-- DELETE RESIDENTS (ADMIN)
--
-- No matching delete policy exists for members below — this stays
-- an admin-only action on purpose.
-- =========================================================
create policy "Admins can delete residents"
on public.residents
for delete
to authenticated
using (public.is_admin());

-- =========================================================
-- VIEW OWN RESIDENT RECORD (MEMBER — self-service)
--
-- A regular (non-admin) member can see only the single resident
-- row linked to their own account. This is a separate permissive
-- policy — Postgres OR's it together with the admin policy above,
-- so it applies even when "Admins can view residents" doesn't.
-- =========================================================
create policy "Members can view own resident record"
on public.residents
for select
to authenticated
using (user_id = auth.uid());

-- =========================================================
-- REGISTER OWN RESIDENT RECORD (MEMBER — self-service)
--
-- A member can create only their own resident row: user_id must
-- be their own id, and they must be the one registering it.
-- =========================================================
create policy "Members can register own resident record"
on public.residents
for insert
to authenticated
with check (
  user_id = auth.uid()
  and registered_by = auth.uid()
);

-- =========================================================
-- UPDATE OWN RESIDENT RECORD (MEMBER — self-service)
--
-- A member can update only their own resident row. with check
-- repeats the condition so they can never re-point the row to
-- someone else's user_id during an update.
-- =========================================================
create policy "Members can update own resident record"
on public.residents
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
