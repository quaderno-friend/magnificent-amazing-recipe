-- ═══════════════════════════════════════════════════════════════════════════
-- Magnificent Amazing Recipe — initial schema
--
-- Reconstructed from the client code: toDb() / fromDb() in src/App.jsx and
-- every supabase.from(...) call. Run this once against a new project, in the
-- Supabase dashboard under SQL Editor → New query → Run.
--
-- Column names must match exactly. The client sends `time_estimate`, not
-- `time`, and reads it back as `time` — a mismatch here shows up as recipes
-- that save but come back with empty fields.
-- ═══════════════════════════════════════════════════════════════════════════


-- ── recipes ────────────────────────────────────────────────────────────────
-- Read with .select('*').order('created_at', {ascending:false}), so created_at
-- must exist and must be populated on insert.

create table if not exists public.recipes (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),

  title          text not null default 'Untitled',
  category       text        default '',
  time_estimate  text        default '',   -- client-side name: `time`
  servings       text        default '',
  notes          text        default '',
  source         text        default 'Manual',

  ingredients    jsonb       not null default '[]'::jsonb,  -- ["500 g flour", "## Levain", …]
  steps          jsonb       not null default '[]'::jsonb,  -- ["Mix…", "Rest 30 min…"]

  notes_pad      text        default '',   -- serialised tab set (NotesPanel)
  thumbnail      text        default '',   -- compressed data: URI
  source_photos  jsonb       not null default '[]'::jsonb,  -- data: URIs of originals
  id_data        text        default '',   -- R&D module blob (IDPanel)
  media_library  text        default '',   -- serialised media entries

  fixed_lang     text,                     -- set on a translated copy, else null
  copied_from    uuid references public.recipes(id) on delete set null,
  is_favorite    boolean     not null default false
);

create index if not exists recipes_created_at_idx on public.recipes (created_at desc);
create index if not exists recipes_category_idx   on public.recipes (category);


-- ── ingredient_library ─────────────────────────────────────────────────────
-- Read with .select('*').order('name'). `params` holds both the standard
-- nutrient keys and any custom ones the user adds, all numeric.

create table if not exists public.ingredient_library (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  ingredient_type  text        default '',
  aliases          jsonb       not null default '[]'::jsonb,  -- ["harina", "farina"]
  params           jsonb       not null default '{}'::jsonb,  -- {"protein": 12.5, …}
  updated_at       timestamptz not null default now()
);

create unique index if not exists ingredient_library_name_idx
  on public.ingredient_library (lower(name));


-- ═══════════════════════════════════════════════════════════════════════════
-- Row Level Security
--
-- ⚠ READ THIS BEFORE GOING LIVE.
--
-- The app has no authentication. There is no sign-in, no user_id column, and
-- no per-user filtering — every client uses the anon key, which ships inside
-- the JavaScript bundle and is readable by anyone who opens the site.
--
-- The policies below therefore grant the anon role full read/write. That is
-- what makes the app work as written, and it means anyone who has the URL and
-- the key can read, edit, or delete every recipe in the project.
--
-- That is acceptable for a private test instance kept behind Netlify's
-- password protection. It is not acceptable for anything public.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.recipes             enable row level security;
alter table public.ingredient_library  enable row level security;

drop policy if exists "anon full access to recipes" on public.recipes;
create policy "anon full access to recipes"
  on public.recipes for all
  to anon, authenticated
  using (true) with check (true);

drop policy if exists "anon full access to ingredient_library" on public.ingredient_library;
create policy "anon full access to ingredient_library"
  on public.ingredient_library for all
  to anon, authenticated
  using (true) with check (true);


-- ── When you add real auth later ───────────────────────────────────────────
-- Add an owner column, backfill it, then swap the policies above for these.
-- Do the backfill before enforcing, or existing rows become invisible.
--
--   alter table public.recipes
--     add column user_id uuid references auth.users(id) on delete cascade;
--
--   update public.recipes set user_id = '<your-auth-uid>' where user_id is null;
--   alter table public.recipes alter column user_id set not null;
--
--   drop policy "anon full access to recipes" on public.recipes;
--   create policy "owner access" on public.recipes for all
--     to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
