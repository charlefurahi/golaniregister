-- =========================================================
-- MIGRATION 007: Change history (audit trail) — ADDITIVE ONLY
--
-- Haigusi public.residents wala data yake iliyopo (hakuna DROP).
-- Haibadilishi jinsi guest anavyosajili/kusasisha — register_public_member()
-- na lookup_public_member() (migration_006, phone+email) zinabaki
-- ndiyo njia PEKEE ya "mshiriki wa kawaida", sawasawa na
-- MemberProfileView.vue ilivyo sasa. Hii inaongeza TU uwezo wa
-- kuona historia ya mabadiliko.
-- =========================================================

-- 1) Indexes za utafutaji (salama kabisa — hazibadilishi data)
create index if not exists residents_full_name_idx on public.residents(full_name);
create index if not exists residents_phone_number_idx on public.residents(phone_number);
create index if not exists residents_full_name_phone_idx on public.residents(full_name, phone_number);
create index if not exists residents_registered_by_idx on public.residents(registered_by);
create index if not exists residents_created_at_idx on public.residents(created_at);

-- 2) Jedwali la historia (CREATE IF NOT EXISTS — si DROP+CREATE)
create table if not exists public.resident_change_history (
  id uuid primary key default gen_random_uuid(),
  resident_id uuid not null references public.residents(id) on delete cascade,
  field_name text not null,
  old_value jsonb,
  new_value jsonb,
  change_type text not null check (change_type in ('INSERT', 'UPDATE')),
  changed_by uuid references auth.users(id) on delete set null, -- NULL = mshiriki wa kawaida (guest, bila login)
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

-- 3) Trigger function: inarekodi INSERT nzima na kila field iliyobadilika
-- kwenye UPDATE. Inafanya kazi kiotomatiki kwa mabadiliko YOTE — ya
-- admin (AdminDashboard.vue, moja kwa moja kwenye jedwali) NA ya guest
-- (register_public_member, ambayo ni SECURITY DEFINER) — kwa sababu
-- trigger inafyatuka kwenye ngazi ya jedwali, bila kujali njia
-- iliyotumika kuandika.
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
    ) values (
      new.id, 'PROFILE_CREATED', null, to_jsonb(new), 'INSERT', auth.uid()
    );
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
        insert into public.resident_change_history (
          resident_id, field_name, old_value, new_value, change_type, changed_by
        ) values (
          new.id, column_name, old_json, new_json, 'UPDATE', auth.uid()
        );
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