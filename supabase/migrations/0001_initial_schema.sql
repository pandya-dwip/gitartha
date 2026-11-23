-- =============================================================================
-- Gitartha (गीतार्थ) — 0001_initial_schema.sql
-- =============================================================================
--
-- Shared-content schema for the Supabase (PostgreSQL) backend.
--
-- What this migration creates (all in the `public` schema):
--   1. app_members                 membership + individual edit permission
--   2. chapters                    the 18 chapters (id = real chapter number)
--   3. shlokas                     the 700 verses and their explanations
--   4. content_sources             translations / commentaries / references
--   5. shloka_source_attributions  which source backs which section of a verse
--
-- What this migration deliberately does NOT create:
--   * Any table for personal data (reflection answers, journal, notes,
--     bookmarks, reading progress/history). Those live ONLY in the on-device
--     SQLite database. See docs/database/LOCAL_SQLITE_SCHEMA.md.
--   * Any scripture content, user accounts, roles, realtime publications,
--     Edge Functions or RPC endpoints that change permissions.
--
-- Security model in one paragraph:
--   Every table has RLS enabled. The `anon` role has no privileges at all.
--   An authenticated user may read shared content only if they have a row in
--   app_members (provisioned automatically, read-only by default). They may
--   write shared content only if their own row has is_accessible = true.
--   No client can insert, update or delete app_members rows; permissions are
--   changed by the project owner in the Supabase SQL Editor (table owner /
--   service role), which is outside application-level RLS.
--
-- Re-running: the script is written to be idempotent (IF NOT EXISTS,
-- CREATE OR REPLACE, ON CONFLICT DO NOTHING, drop-and-recreate for policies
-- only). It never drops tables, columns, schemas or data.
--
-- Requirements: Supabase PostgreSQL 15+ (uses CREATE OR REPLACE TRIGGER and
-- the built-in gen_random_uuid(); no extensions are needed).
-- =============================================================================

begin;


-- =============================================================================
-- 1. EXTENSIONS
-- =============================================================================
-- None required. gen_random_uuid() is built into PostgreSQL 13+.


-- =============================================================================
-- 2. SHARED TIMESTAMP TRIGGER FUNCTIONS
-- =============================================================================

-- Maintains created_at / updated_at on every INSERT and UPDATE.
--
-- * INSERT: created_at and updated_at are both forced to now(), so a client
--   cannot back-date a row (a back-dated updated_at would be skipped by
--   incremental sync on other devices).
-- * UPDATE: created_at is pinned to its original value and updated_at is
--   set to now(). This includes soft deletes (setting deleted_at), which is
--   how devices discover tombstones.
--
-- SECURITY INVOKER (the default): it only touches the row being written.
create or replace function public.set_row_timestamps()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.updated_at := now();
  else
    new.created_at := old.created_at;
    new.updated_at := now();
  end if;
  return new;
end;
$$;

comment on function public.set_row_timestamps() is
  'Trigger: forces created_at/updated_at to server time on INSERT; pins created_at and bumps updated_at on UPDATE.';


-- Rejects any change to a row's primary key.
--
-- Offline devices store chapter ids and shloka UUIDs locally, and personal
-- reflections/notes/bookmarks reference them. Changing an id would silently
-- orphan a user's private data on their device, so ids are immutable for
-- everyone (including the service role; drop the trigger deliberately if a
-- one-off repair is ever truly needed).
create or replace function public.reject_id_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'The id of a % row cannot be changed (old: %, new: %).',
    tg_table_name, old.id, new.id
    using errcode = 'check_violation',
          hint = 'Ids are stable sync keys. Soft-delete the row and insert a new one instead.';
end;
$$;

comment on function public.reject_id_change() is
  'Trigger: forbids changing the primary key of chapters, shlokas and content_sources (stable sync keys).';


-- =============================================================================
-- 3. APPLICATION TABLES
--    (primary keys, foreign keys, UNIQUE and CHECK constraints are inline)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 app_members
-- -----------------------------------------------------------------------------
-- One row per authorized Supabase Auth user. Authentication itself (emails,
-- passwords, sessions) stays in auth.users; nothing here stores credentials.
create table if not exists public.app_members (
  user_id        uuid        not null,
  is_accessible  boolean     not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint app_members_pkey primary key (user_id),

  -- Removing a user from Supabase Auth removes their membership. No shared
  -- content references app_members, so this cascade cannot delete scripture.
  constraint app_members_user_id_fkey foreign key (user_id)
    references auth.users (id) on delete cascade
);

comment on table  public.app_members is
  'Authorized members of Gitartha. A row grants read access to shared content; is_accessible = true additionally grants edit access. Managed only by the project owner.';
comment on column public.app_members.user_id is
  'auth.users.id of the member.';
comment on column public.app_members.is_accessible is
  'Individual permission to add/update/soft-delete shared content. Defaults to false (read-only). Cannot be changed by any client.';


-- -----------------------------------------------------------------------------
-- 3.2 chapters
-- -----------------------------------------------------------------------------
create table if not exists public.chapters (
  id             bigint      not null,
  sanskrit_name  text        not null,
  hindi_name     text        not null,
  english_name   text        not null,
  introduction   text,
  overview       text,
  central_theme  text,
  key_topics     text[],
  summary        text,
  conclusion     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz,

  constraint chapters_pkey primary key (id),

  -- The id IS the chapter number of the Bhagavad Gita.
  constraint chapters_id_range_check check (id between 1 and 18),

  -- Names are required and may not be blank.
  constraint chapters_sanskrit_name_not_blank check (btrim(sanskrit_name) <> ''),
  constraint chapters_hindi_name_not_blank    check (btrim(hindi_name)    <> ''),
  constraint chapters_english_name_not_blank  check (btrim(english_name)  <> ''),

  -- Optional descriptive fields: "not written yet" is NULL, never ''.
  constraint chapters_introduction_not_blank  check (introduction  is null or btrim(introduction)  <> ''),
  constraint chapters_overview_not_blank      check (overview      is null or btrim(overview)      <> ''),
  constraint chapters_central_theme_not_blank check (central_theme is null or btrim(central_theme) <> ''),
  constraint chapters_summary_not_blank       check (summary       is null or btrim(summary)       <> ''),
  constraint chapters_conclusion_not_blank    check (conclusion    is null or btrim(conclusion)    <> ''),
  constraint chapters_key_topics_no_nulls     check (key_topics    is null or array_position(key_topics, null) is null)
);

comment on table  public.chapters is
  'The 18 chapters of the Bhagavad Gita. id is the chapter number (1-18). Soft-deleted via deleted_at. Verse counts are derived from shlokas, not stored.';
comment on column public.chapters.id is
  'Chapter number, 1-18. Stable sync key; cannot be changed after insert.';
comment on column public.chapters.key_topics is
  'Ordered list of key topics for the chapter.';
comment on column public.chapters.deleted_at is
  'Soft-delete tombstone. NULL = live. Readers hide non-NULL rows; sync still downloads them.';


-- -----------------------------------------------------------------------------
-- 3.3 shlokas
-- -----------------------------------------------------------------------------
-- Column order follows the in-app reading order:
--   Sanskrit -> Pronunciation -> Hindi -> English -> Context ->
--   Life Lesson -> Spiritual Meaning -> Reflection Question.
--
-- reflection_question is SHARED content. A user's ANSWER is personal and is
-- stored only on their device; there is intentionally no answer column here.
create table if not exists public.shlokas (
  id                   uuid        not null default gen_random_uuid(),
  chapter_id           bigint      not null,
  verse_number         integer     not null,

  -- "chapter.verse", e.g. '2.47'. Generated, so it can never disagree with
  -- chapter_id / verse_number.
  reference            text        generated always as
                         (chapter_id::text || '.' || verse_number::text) stored,

  -- Verse index (chapter's list of verses)
  index_title          text,
  index_summary        text,

  -- Reading order
  sanskrit_text        text,
  transliteration      text,
  hindi_meaning        text,
  hindi_meaning_note   text,   -- optional clarification shown with the Hindi meaning
  english_meaning      text,
  context              text,
  life_lesson          text,
  spiritual_meaning    text,
  reflection_question  text,

  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  deleted_at           timestamptz,

  constraint shlokas_pkey primary key (id),

  -- RESTRICT: a chapter that still has verses can never be physically
  -- deleted, and nothing cascades through scripture content.
  constraint shlokas_chapter_id_fkey foreign key (chapter_id)
    references public.chapters (id) on update restrict on delete restrict,

  constraint shlokas_verse_number_positive check (verse_number > 0),

  -- One row per (chapter, verse). Also the index used for chapter navigation
  -- (WHERE chapter_id = ? ORDER BY verse_number) and exact verse lookup.
  constraint shlokas_chapter_verse_key unique (chapter_id, verse_number),

  -- Content is filled in gradually: "not written yet" is NULL, never ''.
  constraint shlokas_index_title_not_blank         check (index_title         is null or btrim(index_title)         <> ''),
  constraint shlokas_index_summary_not_blank       check (index_summary       is null or btrim(index_summary)       <> ''),
  constraint shlokas_sanskrit_text_not_blank       check (sanskrit_text       is null or btrim(sanskrit_text)       <> ''),
  constraint shlokas_transliteration_not_blank     check (transliteration     is null or btrim(transliteration)     <> ''),
  constraint shlokas_hindi_meaning_not_blank       check (hindi_meaning       is null or btrim(hindi_meaning)       <> ''),
  constraint shlokas_hindi_meaning_note_not_blank  check (hindi_meaning_note  is null or btrim(hindi_meaning_note)  <> ''),
  constraint shlokas_english_meaning_not_blank     check (english_meaning     is null or btrim(english_meaning)     <> ''),
  constraint shlokas_context_not_blank             check (context             is null or btrim(context)             <> ''),
  constraint shlokas_life_lesson_not_blank         check (life_lesson         is null or btrim(life_lesson)         <> ''),
  constraint shlokas_spiritual_meaning_not_blank   check (spiritual_meaning   is null or btrim(spiritual_meaning)   <> ''),
  constraint shlokas_reflection_question_not_blank check (reflection_question is null or btrim(reflection_question) <> '')
);

comment on table  public.shlokas is
  'Bhagavad Gita verses (700 when complete) with translations and explanations. Shared content only; personal answers are never stored here.';
comment on column public.shlokas.id is
  'Stable UUID sync key. Local reflections/notes/bookmarks reference it; cannot be changed after insert.';
comment on column public.shlokas.reference is
  'Generated "chapter.verse" label, e.g. 2.47.';
comment on column public.shlokas.index_title is
  'Short descriptive title shown in the chapter''s verse index.';
comment on column public.shlokas.index_summary is
  'One-line summary shown in the chapter''s verse index.';
comment on column public.shlokas.transliteration is
  'Pronunciation / Roman transliteration of the Sanskrit.';
comment on column public.shlokas.hindi_meaning_note is
  'Optional historical, linguistic or interpretive clarification accompanying the Hindi meaning.';
comment on column public.shlokas.context is
  'Context: what is happening here?';
comment on column public.shlokas.reflection_question is
  'Shared reflection prompt. Users'' answers are stored only on their device.';
comment on column public.shlokas.deleted_at is
  'Soft-delete tombstone. NULL = live. Readers hide non-NULL rows; sync still downloads them.';


-- -----------------------------------------------------------------------------
-- 3.4 content_sources
-- -----------------------------------------------------------------------------
create table if not exists public.content_sources (
  id           uuid        not null default gen_random_uuid(),
  name         text        not null,
  author       text,
  source_url   text,
  license      text,
  attribution  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint content_sources_pkey primary key (id),

  constraint content_sources_name_not_blank        check (btrim(name) <> ''),
  constraint content_sources_author_not_blank      check (author      is null or btrim(author)      <> ''),
  constraint content_sources_license_not_blank     check (license     is null or btrim(license)     <> ''),
  constraint content_sources_attribution_not_blank check (attribution is null or btrim(attribution) <> ''),
  constraint content_sources_source_url_http       check (source_url  is null or source_url ~* '^https?://[^[:space:]]+$')
);

comment on table  public.content_sources is
  'Translations, commentaries and references used for shloka content, with licensing/attribution. Soft-deleted via deleted_at.';
comment on column public.content_sources.license is
  'License or permission terms (e.g. "Public domain", "CC BY-SA 4.0", "Used with written permission"). NULL = not yet verified; do not assume reuse is allowed.';
comment on column public.content_sources.attribution is
  'Exact attribution text that must be displayed when content from this source is shown.';


-- -----------------------------------------------------------------------------
-- 3.5 shloka_source_attributions
-- -----------------------------------------------------------------------------
-- Maps one section of one shloka to one source. Rows are immutable: to change
-- a mapping, delete it and insert a new one (there is no updated_at column,
-- so in-place edits would be invisible to incremental sync).
create table if not exists public.shloka_source_attributions (
  id               uuid        not null default gen_random_uuid(),
  shloka_id        uuid        not null,
  source_id        uuid        not null,
  content_section  text        not null,
  created_at       timestamptz not null default now(),

  constraint shloka_source_attributions_pkey primary key (id),

  -- RESTRICT: attributions never cascade-delete, and a shloka/source that is
  -- still referenced can't be physically purged by accident.
  constraint shloka_source_attributions_shloka_id_fkey foreign key (shloka_id)
    references public.shlokas (id) on update restrict on delete restrict,
  constraint shloka_source_attributions_source_id_fkey foreign key (source_id)
    references public.content_sources (id) on update restrict on delete restrict,

  constraint shloka_source_attributions_content_section_check check (
    content_section in (
      'sanskrit_text',
      'transliteration',
      'hindi_meaning',
      'hindi_meaning_note',
      'english_meaning',
      'context',
      'life_lesson',
      'spiritual_meaning',
      'reflection_question'
    )
  ),

  -- No duplicate (shloka, source, section) mapping. Its leading column also
  -- serves as the index for the shloka_id foreign key.
  constraint shloka_source_attributions_mapping_key
    unique (shloka_id, source_id, content_section)
);

comment on table  public.shloka_source_attributions is
  'Links a section of a shloka to the content source it came from. Immutable rows; editors insert and delete.';
comment on column public.shloka_source_attributions.content_section is
  'Which shloka field the source covers. Must match a shlokas column name.';


-- =============================================================================
-- 4. INDEXES
-- =============================================================================
-- Already provided by constraints:
--   chapters_pkey (id)                                   chapter lookup
--   shlokas_pkey (id)                                    verse lookup by UUID
--   shlokas_chapter_verse_key (chapter_id, verse_number) navigation, lookup,
--                                                        and the chapter_id FK
--   shloka_source_attributions_mapping_key
--     (shloka_id, source_id, content_section)            the shloka_id FK
--
-- Incremental sync reads "everything changed since T" in pages ordered by
-- (updated_at, id). These composite indexes serve that keyset pagination.

create index if not exists chapters_updated_at_id_idx
  on public.chapters (updated_at, id);

create index if not exists shlokas_updated_at_id_idx
  on public.shlokas (updated_at, id);

create index if not exists content_sources_updated_at_id_idx
  on public.content_sources (updated_at, id);

-- Foreign key index for source_id (lookups by source, and FK checks when a
-- source is purged).
create index if not exists shloka_source_attributions_source_id_idx
  on public.shloka_source_attributions (source_id);

-- Pull-by-time for attributions, which have no updated_at.
create index if not exists shloka_source_attributions_created_at_id_idx
  on public.shloka_source_attributions (created_at, id);


-- =============================================================================
-- 5. TIMESTAMP AND ID-STABILITY TRIGGERS
-- =============================================================================

create or replace trigger app_members_set_timestamps
  before insert or update on public.app_members
  for each row execute function public.set_row_timestamps();

create or replace trigger chapters_set_timestamps
  before insert or update on public.chapters
  for each row execute function public.set_row_timestamps();

create or replace trigger shlokas_set_timestamps
  before insert or update on public.shlokas
  for each row execute function public.set_row_timestamps();

create or replace trigger content_sources_set_timestamps
  before insert or update on public.content_sources
  for each row execute function public.set_row_timestamps();

create or replace trigger chapters_reject_id_change
  before update on public.chapters
  for each row when (old.id is distinct from new.id)
  execute function public.reject_id_change();

create or replace trigger shlokas_reject_id_change
  before update on public.shlokas
  for each row when (old.id is distinct from new.id)
  execute function public.reject_id_change();

create or replace trigger content_sources_reject_id_change
  before update on public.content_sources
  for each row when (old.id is distinct from new.id)
  execute function public.reject_id_change();


-- =============================================================================
-- 6. MEMBERSHIP PERMISSION HELPER FUNCTIONS
-- =============================================================================
-- Used inside RLS policies. Both are SECURITY INVOKER on purpose:
--
--   * They read public.app_members as the calling user, so they only ever see
--     the caller's own row (app_members' SELECT policy is user_id = auth.uid()).
--   * There is no recursion: app_members' own policy does not call them.
--   * They take no arguments, so a client cannot ask about another user.
--   * They only read; there is no function anywhere that changes permissions.
--
-- Anonymous Supabase sign-ins (if ever enabled) also use the `authenticated`
-- role. They are excluded explicitly via the JWT's is_anonymous claim, in
-- addition to never being given a membership row (see section 7).

create or replace function public.is_app_member()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    and exists (
      select 1
      from public.app_members m
      where m.user_id = auth.uid()
    );
$$;

comment on function public.is_app_member() is
  'True when the current (non-anonymous) authenticated user has an app_members row. Takes no arguments; reads only the caller''s own row.';


create or replace function public.can_edit_shared_content()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
    and coalesce(
      (
        select m.is_accessible
        from public.app_members m
        where m.user_id = auth.uid()
      ),
      false
    );
$$;

comment on function public.can_edit_shared_content() is
  'True when the current (non-anonymous) authenticated user''s own app_members.is_accessible is true. Takes no arguments; reads only the caller''s own row.';

-- Only signed-in clients need these (policies run them as the caller).
revoke all on function public.is_app_member()           from public, anon;
revoke all on function public.can_edit_shared_content() from public, anon;
grant execute on function public.is_app_member()           to authenticated, service_role;
grant execute on function public.can_edit_shared_content() to authenticated, service_role;

-- Trigger functions are never called directly by clients.
revoke all on function public.set_row_timestamps() from public, anon, authenticated;
revoke all on function public.reject_id_change()   from public, anon, authenticated;


-- =============================================================================
-- 7. NEW-USER MEMBERSHIP PROVISIONING
-- =============================================================================
-- When Supabase Auth creates a user (for an invite-only project: when the
-- owner sends an invite or creates the user in the dashboard), give them a
-- read-only membership row.
--
-- SECURITY DEFINER is genuinely required here: the trigger runs as the
-- Supabase Auth service role (supabase_auth_admin), which has no privileges
-- on public.app_members. Safeguards:
--   * fixed, empty search_path; every name is schema-qualified;
--   * returns `trigger`, so it cannot be called as an RPC or from SQL;
--   * EXECUTE revoked from every client role;
--   * it can only ever insert is_accessible = false for the user that was
--     just created, and never modifies an existing row (ON CONFLICT DO NOTHING);
--   * anonymous users are skipped.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(new.is_anonymous, false) then
    return new;
  end if;

  insert into public.app_members (user_id, is_accessible)
  values (new.id, false)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

comment on function public.handle_new_auth_user() is
  'Trigger on auth.users: provisions a read-only (is_accessible = false) app_members row for every new non-anonymous user.';

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;

create or replace trigger on_auth_user_created_provision_membership
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Backfill: users that already existed before this migration also get a
-- read-only membership. Existing rows (and their permissions) are untouched.
insert into public.app_members (user_id, is_accessible)
select u.id, false
from auth.users u
where coalesce(u.is_anonymous, false) = false
on conflict (user_id) do nothing;


-- =============================================================================
-- 8. TABLE PRIVILEGES
-- =============================================================================
-- Supabase grants ALL on new public tables to anon and authenticated by
-- default. Start from nothing and grant only what the policies below need.
-- This also removes TRUNCATE (which bypasses RLS) and physical DELETE on
-- scripture tables.

revoke all on table
  public.app_members,
  public.chapters,
  public.shlokas,
  public.content_sources,
  public.shloka_source_attributions
from public, anon, authenticated;

-- Members read their own membership row. No insert/update/delete at all.
grant select on table public.app_members to authenticated;

-- Shared content: read for members; insert/update (incl. soft delete) for
-- editors, as filtered by RLS. No DELETE: removal is a soft delete.
grant select, insert, update on table
  public.chapters,
  public.shlokas,
  public.content_sources
to authenticated;

-- Attributions are immutable rows: editors insert and (physically) delete.
grant select, insert, delete on table public.shloka_source_attributions to authenticated;

-- The service role (server-side admin processes, never shipped in the app)
-- keeps full access; it bypasses RLS by design.
grant all on table
  public.app_members,
  public.chapters,
  public.shlokas,
  public.content_sources,
  public.shloka_source_attributions
to service_role;


-- =============================================================================
-- 9. ROW LEVEL SECURITY
-- =============================================================================
-- Enabled (not forced): the table owner — i.e. the project owner in the
-- Supabase SQL Editor — and the service role are not subject to RLS. That is
-- how permissions are granted and revoked.

alter table public.app_members                enable row level security;
alter table public.chapters                   enable row level security;
alter table public.shlokas                    enable row level security;
alter table public.content_sources            enable row level security;
alter table public.shloka_source_attributions enable row level security;


-- -----------------------------------------------------------------------------
-- 9.1 SELECT policies
-- -----------------------------------------------------------------------------
-- `(select fn())` lets PostgreSQL evaluate the check once per statement
-- instead of once per row.
--
-- Content SELECT policies intentionally return soft-deleted rows too: sync
-- needs tombstones. Reading screens filter `deleted_at is null` (locally).

drop policy if exists app_members_select_own on public.app_members;
create policy app_members_select_own
  on public.app_members
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists chapters_select_members on public.chapters;
create policy chapters_select_members
  on public.chapters
  for select
  to authenticated
  using ((select public.is_app_member()));

drop policy if exists shlokas_select_members on public.shlokas;
create policy shlokas_select_members
  on public.shlokas
  for select
  to authenticated
  using ((select public.is_app_member()));

drop policy if exists content_sources_select_members on public.content_sources;
create policy content_sources_select_members
  on public.content_sources
  for select
  to authenticated
  using ((select public.is_app_member()));

drop policy if exists shloka_source_attributions_select_members on public.shloka_source_attributions;
create policy shloka_source_attributions_select_members
  on public.shloka_source_attributions
  for select
  to authenticated
  using ((select public.is_app_member()));


-- -----------------------------------------------------------------------------
-- 9.2 INSERT policies (editors only)
-- -----------------------------------------------------------------------------
-- app_members: no INSERT policy and no INSERT grant. Rows are created only by
-- the provisioning trigger or by the project owner.

drop policy if exists chapters_insert_editors on public.chapters;
create policy chapters_insert_editors
  on public.chapters
  for insert
  to authenticated
  with check ((select public.can_edit_shared_content()));

drop policy if exists shlokas_insert_editors on public.shlokas;
create policy shlokas_insert_editors
  on public.shlokas
  for insert
  to authenticated
  with check ((select public.can_edit_shared_content()));

drop policy if exists content_sources_insert_editors on public.content_sources;
create policy content_sources_insert_editors
  on public.content_sources
  for insert
  to authenticated
  with check ((select public.can_edit_shared_content()));

drop policy if exists shloka_source_attributions_insert_editors on public.shloka_source_attributions;
create policy shloka_source_attributions_insert_editors
  on public.shloka_source_attributions
  for insert
  to authenticated
  with check ((select public.can_edit_shared_content()));


-- -----------------------------------------------------------------------------
-- 9.3 UPDATE policies (editors only; also covers soft delete and restore)
-- -----------------------------------------------------------------------------
-- app_members: no UPDATE policy and no UPDATE grant, so no client can change
-- is_accessible — their own or anyone else's.
-- shloka_source_attributions: no UPDATE (immutable rows).

drop policy if exists chapters_update_editors on public.chapters;
create policy chapters_update_editors
  on public.chapters
  for update
  to authenticated
  using ((select public.can_edit_shared_content()))
  with check ((select public.can_edit_shared_content()));

drop policy if exists shlokas_update_editors on public.shlokas;
create policy shlokas_update_editors
  on public.shlokas
  for update
  to authenticated
  using ((select public.can_edit_shared_content()))
  with check ((select public.can_edit_shared_content()));

drop policy if exists content_sources_update_editors on public.content_sources;
create policy content_sources_update_editors
  on public.content_sources
  for update
  to authenticated
  using ((select public.can_edit_shared_content()))
  with check ((select public.can_edit_shared_content()));


-- -----------------------------------------------------------------------------
-- 9.4 DELETE policies
-- -----------------------------------------------------------------------------
-- chapters, shlokas, content_sources: none (and no DELETE grant). Removal is
-- a soft delete: UPDATE ... SET deleted_at = now().
-- app_members: none. Only the project owner removes members.
-- shloka_source_attributions: editors may physically delete a mapping.

drop policy if exists shloka_source_attributions_delete_editors on public.shloka_source_attributions;
create policy shloka_source_attributions_delete_editors
  on public.shloka_source_attributions
  for delete
  to authenticated
  using ((select public.can_edit_shared_content()));


-- =============================================================================
-- 10. INITIAL APPLICATION CONFIGURATION
-- =============================================================================
-- None. No content, accounts or settings are seeded. (The only data written
-- is the read-only membership backfill in section 7.)

commit;
