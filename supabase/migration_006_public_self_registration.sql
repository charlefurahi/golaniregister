-- Migration 006: Public (no-login) self-registration for church members
--
-- LENGO: mshiriki wa kawaida aweze kujaza fomu YAKE MWENYEWE bila
-- kulogin wala kutengeneza akaunti ya Supabase Auth. Taarifa zake
-- zinahifadhiwa moja kwa moja kwenye public.residents, na admin
-- anaendelea kuziona kwenye AdminDashboard kama kawaida — sera za
-- is_admin() zilizopo tayari (schema.sql) zinashughulikia hilo,
-- HAZIHITAJI kubadilishwa.
--
-- MUUNDO WA USALAMA: role ya "anon" (mtumiaji asiye-login) HAIPEWI
-- ruhusa ya moja kwa moja ya SELECT/INSERT/UPDATE kwenye residents —
-- hilo lingefungua jedwali lote kwa umma. Badala yake tunatumia
-- FUNCTIONS mbili za SECURITY DEFINER; hizi pekee ndizo zenye ruhusa
-- ya kuandika/kusoma, na kila moja inadhibiti kwa makini nini
-- kinaonekana/kinabadilika. Hii inafanya kazi kwa sababu functions
-- zilizotengenezwa humu (Supabase SQL Editor) zinamilikiwa na role
-- ya "postgres" yenye BYPASSRLS — mbinu hii hii tayari inatumika na
-- register_family()/update_member_with_family() kwenye schema_v3.
--
-- FARAGHA: lookup_public_member() inarudisha taarifa ZOTE za mtu kwa
-- yeyote anayejua NAMBA YA SIMU NA BARUA PEPE zake ZOTE MBILI (si
-- moja tu) — hii ndiyo inayowezesha "auto-load ili kuepuka
-- duplication" uliyoomba. Kwa kanisa hatari hii ni ndogo, lakini
-- ifahamike kabla ya kuweka live.

-- =========================================================
-- Alama ya chanzo cha rekodi (msaada tu kwa admin UI baadaye)
-- =========================================================
alter table public.residents
  add column if not exists is_self_registered boolean not null default false;

-- =========================================================
-- Vifaa vya ku-normalize (sawa na normalizeValue/normalizePhone
-- za AdminDashboard.vue, ili duplicate-matching ilingane pande
-- zote mbili — admin panel na fomu ya umma)
-- =========================================================
create or replace function public.normalize_phone(p text)
returns text
language sql
immutable
as $$
  select regexp_replace(coalesce(p, ''), '\D', '', 'g');
$$;

create or replace function public.normalize_email(p text)
returns text
language sql
immutable
as $$
  select lower(trim(coalesce(p, '')));
$$;

-- =========================================================
-- 1) LOOKUP: guest anaingiza phone+email, tunatafuta rekodi yake
--    ya awali (kama ipo) ili fomu ijae yenyewe.
-- =========================================================
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

-- =========================================================
-- 2) REGISTER / UPDATE: ikiwa phone+email vinalingana na rekodi
--    iliyopo, tuna-UPDATE row hiyo (kuepuka duplicate). Vinginevyo
--    tunaingiza row mpya.
-- =========================================================
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
begin
  if nullif(trim(p->>'full_name'), '') is null then
    raise exception 'Jina langu kamili linahitajika.' using errcode = '22023';
  end if;
  if nullif(trim(p->>'gender'), '') is null then
    raise exception 'Jinsia yangu inahitajika.' using errcode = '22023';
  end if;

  if public.normalize_phone(p->>'phone_number') <> ''
     and public.normalize_email(p->>'email') <> '' then
    select id into v_existing_id
    from public.residents
    where public.normalize_phone(phone_number) = public.normalize_phone(p->>'phone_number')
      and public.normalize_email(email) = public.normalize_email(p->>'email')
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

  return jsonb_build_object(
    'id', v_row.id,
    'was_update', v_was_update
  );
end;
$$;

revoke all on function public.register_public_member(jsonb) from public;
grant execute on function public.register_public_member(jsonb) to anon, authenticated;

-- =========================================================
-- Kumbuka: HATUONGEZI sera yoyote ya RLS ya INSERT/UPDATE kwa
-- "anon" kwenye residents moja kwa moja. Njia pekee ya "anon"
-- kuandika ni kupitia functions mbili hapo juu, ambazo zote
-- zinathibitisha full_name/gender kabla ya kuandika chochote.
-- =========================================================