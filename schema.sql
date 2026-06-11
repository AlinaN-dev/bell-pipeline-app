-- ============================================================================
--  Bell AI Fabric — Data Centre Pipeline Tracker
--  Database schema for Supabase (PostgreSQL)
--
--  HOW TO RUN (once):
--    1. Open your Supabase project
--    2. Left sidebar -> SQL Editor -> New query
--    3. Paste this whole file and click "Run"
--  That's it. The app fills the tables with your 22 starter sites on first load.
-- ============================================================================

-- ---- Sites: one row per data-centre site ----------------------------------
create table if not exists public.sites (
  id          text primary key,
  stage       text not null default 'mid',     -- ops | con | near | mid
  name        text not null,
  location    text,
  prov        text,
  mw          double precision default 0,       -- gross capacity
  mw_label    text,                             -- optional display override
  customers   jsonb default '[]'::jsonb,        -- [{ "n": name|null, "mw": number, "prospect": bool }]
  confidential boolean default false,           -- mask customer names in External view
  facility    text,
  head_lease  text,
  landlord    text,
  purchase    text,
  lease_terms text,
  lease_type  text,
  rfs         text,
  deal_exec   text,
  power       text,
  power_state text,                             -- live | review | none
  comments    text,                             -- internal-only notes
  custom      boolean default false,            -- true = added in-app (not a starter site)
  sort        integer default 500,              -- display order
  created_at  timestamptz default now()
);

-- ---- Updates: the dated change log, many per site -------------------------
create table if not exists public.updates (
  id            uuid primary key default gen_random_uuid(),
  site_id       text references public.sites(id) on delete cascade,
  date          date,
  text          text not null,
  internal_only boolean default false,          -- hidden in External view
  auto          boolean default false,          -- true = system note (e.g. stage moved)
  created_at    timestamptz default now()
);

create index if not exists updates_site_id_idx on public.updates(site_id);

-- ---- Access policy --------------------------------------------------------
--  You chose: one link, everyone sees and edits everything.
--  These policies allow anyone with the link (the anon key) to read & write.
--  If you later want to lock editing down, replace the policies below.
alter table public.sites   enable row level security;
alter table public.updates enable row level security;

create policy "open read sites"    on public.sites   for select using (true);
create policy "open insert sites"  on public.sites   for insert with check (true);
create policy "open update sites"  on public.sites   for update using (true) with check (true);
create policy "open delete sites"  on public.sites   for delete using (true);

create policy "open read updates"   on public.updates for select using (true);
create policy "open insert updates" on public.updates for insert with check (true);
create policy "open update updates" on public.updates for update using (true) with check (true);
create policy "open delete updates" on public.updates for delete using (true);

-- ---- Live updates (so edits appear for everyone without refreshing) -------
--  If either line errors with "already member of publication", ignore it.
alter publication supabase_realtime add table public.sites;
alter publication supabase_realtime add table public.updates;
