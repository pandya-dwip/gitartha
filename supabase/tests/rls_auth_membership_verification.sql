-- =============================================================================
-- Gitartha — RLS verification: authentication & individual membership
-- =============================================================================
--
-- Proves, against a real database, that the access model in
-- 0001_initial_schema.sql holds regardless of what the Flutter app does:
--
--   * new Auth users get a READ-ONLY membership (even with crafted metadata);
--   * members see only their own app_members row and cannot change any
--     membership (their own or anyone else's), including editors;
--   * read-only members can read scripture but every write is rejected;
--   * editors (is_accessible = true) can insert / update / soft-delete;
--   * signed-in users without a membership, and anon, can read nothing.
--
-- RUN ONLY ON AN ISOLATED PROJECT: `supabase start` (local) or a throwaway
-- Supabase project. Never on production.
--
-- How: paste into the SQL Editor (or `psql -f`) as the project owner
-- (postgres). Everything runs in ONE transaction that ends in ROLLBACK, so
-- no test users or rows are kept. Any failed check raises an exception that
-- names it (and the rollback still happens). Success ends with the notice
-- "ALL RLS CHECKS PASSED".
--
-- Impersonation: `set local role authenticated` + request.jwt.claims is how
-- PostgREST runs a signed-in user's request; auth.uid() reads `sub`.
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Setup (as owner): three fake users. The reader even *asks* for editing via
-- user metadata, which a client controls — it must be ignored.
-- ---------------------------------------------------------------------------
insert into auth.users
  (instance_id, id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-0000000000a1',
   'authenticated', 'authenticated', 'rls-reader@example.test', '{}', '{"is_accessible": true}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-0000000000a2',
   'authenticated', 'authenticated', 'rls-editor@example.test', '{}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-0000000000a3',
   'authenticated', 'authenticated', 'rls-outsider@example.test', '{}', '{}', now(), now());

do $$ begin
  if (select count(*) from public.app_members
      where user_id in ('00000000-0000-4000-8000-0000000000a1',
                        '00000000-0000-4000-8000-0000000000a2',
                        '00000000-0000-4000-8000-0000000000a3')
        and is_accessible = false) <> 3 then
    raise exception 'FAIL provisioning: trigger did not create 3 read-only memberships (metadata must not grant editing)';
  end if;
end $$;

-- Owner grants editing to the editor and removes the outsider's membership.
update public.app_members set is_accessible = true  where user_id = '00000000-0000-4000-8000-0000000000a2';
delete from public.app_members                        where user_id = '00000000-0000-4000-8000-0000000000a3';

-- A chapter to read and write (kept if it already exists; all rolled back).
insert into public.chapters (id, sanskrit_name, hindi_name, english_name)
values (18, 'RLS TEST', 'RLS TEST', 'RLS TEST')
on conflict (id) do nothing;


-- ---------------------------------------------------------------------------
-- READ-ONLY MEMBER
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000000000a1","role":"authenticated","is_anonymous":false}', true);
set local role authenticated;

do $$
declare n int;
begin
  -- Own membership only.
  if (select count(*) from public.app_members) <> 1
     or (select user_id from public.app_members) <> auth.uid() then
    raise exception 'FAIL reader: can see membership rows other than their own';
  end if;
  if not public.is_app_member() or public.can_edit_shared_content() then
    raise exception 'FAIL reader: helper functions report wrong permission';
  end if;

  -- Can read scripture.
  if (select count(*) from public.chapters where id = 18) <> 1 then
    raise exception 'FAIL reader: cannot read chapters';
  end if;

  -- Cannot grant themselves editing.
  begin
    update public.app_members set is_accessible = true where user_id = auth.uid();
    raise exception 'FAIL reader: updated own is_accessible';
  exception when insufficient_privilege then null;
  end;
  -- Cannot change anyone else's permission.
  begin
    update public.app_members set is_accessible = false
    where user_id = '00000000-0000-4000-8000-0000000000a2';
    raise exception 'FAIL reader: updated another member''s permission';
  exception when insufficient_privilege then null;
  end;
  -- Cannot create or delete memberships.
  begin
    insert into public.app_members (user_id, is_accessible)
    values ('00000000-0000-4000-8000-0000000000a3', true);
    raise exception 'FAIL reader: inserted a membership';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.app_members where user_id = auth.uid();
    raise exception 'FAIL reader: deleted a membership';
  exception when insufficient_privilege then null;
  end;

  -- Writes to shared content are rejected.
  update public.chapters set english_name = 'hacked' where id = 18;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL reader: updated a chapter'; end if;

  update public.chapters set deleted_at = now() where id = 18;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL reader: soft-deleted a chapter'; end if;

  begin
    insert into public.content_sources (name) values ('RLS TEST reader source');
    raise exception 'FAIL reader: inserted a content source';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.shlokas (chapter_id, verse_number) values (18, 998);
    raise exception 'FAIL reader: inserted a shloka';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.shloka_source_attributions (shloka_id, source_id, content_section)
    values (gen_random_uuid(), gen_random_uuid(), 'english_meaning');
    raise exception 'FAIL reader: inserted an attribution';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.chapters where id = 18;
    raise exception 'FAIL reader: physically deleted a chapter';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;


-- ---------------------------------------------------------------------------
-- EDITOR (is_accessible = true)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000000000a2","role":"authenticated","is_anonymous":false}', true);
set local role authenticated;

do $$
declare
  n   int;
  src uuid;
  shl uuid;
begin
  if not public.can_edit_shared_content() then
    raise exception 'FAIL editor: can_edit_shared_content() is false';
  end if;

  update public.chapters set english_name = english_name where id = 18;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL editor: could not update a chapter'; end if;

  insert into public.content_sources (name) values ('RLS TEST editor source') returning id into src;
  insert into public.shlokas (chapter_id, verse_number) values (18, 999) returning id into shl;
  insert into public.shloka_source_attributions (shloka_id, source_id, content_section)
  values (shl, src, 'english_meaning');

  update public.shlokas set deleted_at = now() where id = shl;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL editor: could not soft-delete a shloka'; end if;

  delete from public.shloka_source_attributions where shloka_id = shl;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL editor: could not delete an attribution'; end if;

  -- Editors still cannot touch permissions, nor physically delete content.
  begin
    update public.app_members set is_accessible = true
    where user_id = '00000000-0000-4000-8000-0000000000a1';
    raise exception 'FAIL editor: changed another member''s permission';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.shlokas where id = shl;
    raise exception 'FAIL editor: physically deleted a shloka';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;


-- ---------------------------------------------------------------------------
-- SIGNED IN, NO MEMBERSHIP
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000000000a3","role":"authenticated","is_anonymous":false}', true);
set local role authenticated;

do $$ begin
  if (select count(*) from public.chapters) <> 0 then
    raise exception 'FAIL outsider: can read chapters without a membership';
  end if;
  if (select count(*) from public.app_members) <> 0 then
    raise exception 'FAIL outsider: can see membership rows';
  end if;
  begin
    insert into public.content_sources (name) values ('RLS TEST outsider source');
    raise exception 'FAIL outsider: inserted a content source';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;


-- ---------------------------------------------------------------------------
-- ANON (publishable key, no session)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

do $$ begin
  begin
    perform 1 from public.chapters limit 1;
    raise exception 'FAIL anon: can read chapters';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.app_members limit 1;
    raise exception 'FAIL anon: can read app_members';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;

do $$ begin raise notice 'ALL RLS CHECKS PASSED'; end $$;

rollback;
