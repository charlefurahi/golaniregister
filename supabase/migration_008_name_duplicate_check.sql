-- Migration 008: Name-based duplicate warning for public self-registration
--
-- LENGO: mshiriki (guest, bila login) anapoanza kujaza JINA lake,
-- MemberProfileView.vue inauliza check_name_duplicate() ili kumjulisha
-- kama tayari kuna aliyesajiliwa kwa jina kama hilo — ili achague:
--   (A) "Ndiyo, ni mimi"       -> aendelee kujaza namba ya simu +
--       barua pepe yake ya awali; lookup_public_member() (migration_006)
--       ndiyo itakayompakulia taarifa zake halisi (haibadiliki hapa).
--   (B) "Hapana, ni mtu tofauti" -> aendelee kujaza fomu yake mpya
--       bila kuguswa na taarifa za mwenzake.
--
-- FARAGHA: check_name_duplicate() HAIRUDISHI taarifa kamili za mtu.
-- Jina peke yake ni rahisi sana kulijua/kulibashiri (si siri kama
-- phone+email pamoja), hivyo kurudisha rekodi nzima kwa JINA TU
-- kungefungua taarifa za mshiriki (namba yake, email yake, watoto
-- wake n.k) kwa mtu yeyote anayejua tu jina lake. Function hii
-- inarudisha dalili ndogo isiyo hatarishi tu: kwamba jina lipo,
-- idadi ya wanaofanana, na tarakimu 2 za mwisho za namba ya simu —
-- za kutosha kumkumbusha mwenye akaunti, bila kufichua chochote kwa
-- mtu asiyehusika.
--
-- Pia tunabadilisha (CREATE OR REPLACE) register_public_member() ili
-- kutambua "mtu yule yule" kwa njia mbili za ziada, si simu+email tu:
--   - jina + namba ya simu vinalingana (email pengine imebadilika/
--     imekosewa wakati wa kujaza), AU
--   - jina + tarehe ya kuzaliwa vinalingana (namba pengine imebadilika).
-- Tukiona mojawapo, tuna-UPDATE rekodi iliyopo badala ya kuunda mpya.
-- Kwa MAKUSUDI hatutumii JINA PEKEE kuamua "mtu yule yule" kiotomatiki
-- (bila uthibitisho wa pili) — watu wawili tofauti wanaweza kuwa na
-- jina moja, na kufanya hivyo kungeweza kumfanya mmoja aandike juu ya
-- taarifa za mwenzake bila kujua. Hilo ndilo linalozuiwa na banner ya
-- "Je, huyu ni wewe?" iliyoongezwa upande wa MemberProfileView.vue.
-- =========================================================

-- =========================================================
-- 1) Kifaa cha ku-normalize jina (sawa na normalizeValue() ya
--    AdminDashboard.vue: lowercase + trim + nafasi moja kati ya maneno)
-- =========================================================
create or replace function public.normalize_name(p text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(coalesce(p, '')), '\s+', ' ', 'g'));
$$;

-- =========================================================
-- 2) ONYO LA JINA LINALOFANANA (anon-safe — haifichui taarifa kamili)
-- =========================================================
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
      when v_phone is not null and length(v_phone) >= 2
        then right(v_phone, 2)
      else null
    end
  );
end;
$$;

revoke all on function public.check_name_duplicate(text) from public;
grant execute on function public.check_name_duplicate(text) to anon, authenticated;

-- =========================================================
-- 3) REGISTER / UPDATE — muundo ule ule wa migration_006, TU
--    tumeongeza njia mbili za ziada za kutambua "mtu yule yule":
--    (jina + simu) au (jina + tarehe ya kuzaliwa), pamoja na
--    (simu + email) iliyokuwepo tayari.
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

  -- (a) simu + email zinalingana kikamilifu (kama ilivyokuwa awali)
  if v_phone <> '' and v_email <> '' then
    select id into v_existing_id
    from public.residents
    where public.normalize_phone(phone_number) = v_phone
      and public.normalize_email(email) = v_email
    limit 1;
  end if;

  -- (b) jina + simu vinalingana (email pengine imebadilika/imekosewa)
  if v_existing_id is null and v_name <> '' and v_phone <> '' then
    select id into v_existing_id
    from public.residents
    where public.normalize_name(full_name) = v_name
      and public.normalize_phone(phone_number) = v_phone
    limit 1;
  end if;

  -- (c) jina + tarehe ya kuzaliwa vinalingana (namba pengine imebadilika)
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

  return jsonb_build_object(
    'id', v_row.id,
    'was_update', v_was_update
  );
end;
$$;

revoke all on function public.register_public_member(jsonb) from public;
grant execute on function public.register_public_member(jsonb) to anon, authenticated;

-- =========================================================
-- Kumbuka: bado HATUONGEZI ruhusa yoyote ya SELECT/INSERT/UPDATE
-- ya moja kwa moja kwa "anon" kwenye residents. Njia pekee za "anon"
-- kuandika/kusoma ni functions hizi (na lookup_public_member ya
-- migration_006), zote SECURITY DEFINER na zinazodhibiti kwa makini
-- kinachoonekana/kinachobadilika.
-- =========================================================