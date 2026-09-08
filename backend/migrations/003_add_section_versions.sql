-- Migration 003: section versions for split-view editing
-- ----------------------------------------------------------------------
-- Adds section_versions table backing per-section history and working copies.
-- When non-owners save edits in the split-view editor, they are saved here
-- without overwriting the approved copy in project_sections.
--
-- Run this once in the Supabase SQL editor:
--   (Project -> SQL -> New query -> paste -> Run).

CREATE TABLE IF NOT EXISTS public.section_versions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  section_key text NOT NULL,
  content text NOT NULL DEFAULT '',
  edited_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  message text,
  CONSTRAINT section_versions_pkey PRIMARY KEY (id),
  CONSTRAINT section_versions_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT section_versions_edited_by_fkey FOREIGN KEY (edited_by) REFERENCES public.profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_section_versions_lookup
  ON public.section_versions (project_id, section_key, created_at DESC);
