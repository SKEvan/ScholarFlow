-- Migration 001: add editable "about" column to public.profiles
-- ----------------------------------------------------
-- The Profile screen now displays and lets the user edit a free-form
-- "about" bio. Until this migration is applied the column does not
-- exist on the table, so any upsert that references "about" will be
-- silently ignored by PostgREST.
--
-- Run this once in the Supabase SQL editor
--   (Project -> SQL -> New query -> paste -> Run).
-- It is safe to re-run; the IF NOT EXISTS guard makes it idempotent.
--
-- After running, no backend restart is required - GET responses start
-- returning "about" on the next request because /profiles uses
-- select=*. PATCH requests that include "about" will persist.

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS about text;
