-- Migration 002: role-based section ownership + edit-approval workflow
-- ----------------------------------------------------------------------
-- Adds two tables backing the four draft paper sections (Abstract,
-- Introduction, Literature Review, Methodology):
--
--   * project_sections            - one row per (project, section): who
--                                    owns it and its current APPROVED
--                                    content. The project's owner_id
--                                    (the "leader") assigns owner_user_id.
--                                    The assigned owner's edits write here
--                                    directly. Missing rows are treated as
--                                    an unowned, empty section by the API
--                                    (no row is created until first touch).
--
--   * project_section_edit_requests - a pending/approved/rejected edit
--                                    proposed by a non-owner. Approving one
--                                    copies its proposed_content into the
--                                    matching project_sections row. Rows
--                                    are never deleted, so this table also
--                                    doubles as a history log.
--
-- Run this once in the Supabase SQL editor
--   (Project -> SQL -> New query -> paste -> Run).
-- It is safe to re-run; IF NOT EXISTS / ON CONFLICT-free guards make the
-- table creation idempotent.

CREATE TABLE IF NOT EXISTS public.project_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  section_key text NOT NULL,
  owner_user_id uuid,
  approved_content text NOT NULL DEFAULT '',
  approved_by uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT project_sections_pkey PRIMARY KEY (id),
  CONSTRAINT project_sections_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT project_sections_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.profiles(id),
  CONSTRAINT project_sections_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.profiles(id),
  CONSTRAINT project_sections_unique_key UNIQUE (project_id, section_key)
);

CREATE TABLE IF NOT EXISTS public.project_section_edit_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  section_key text NOT NULL,
  author_user_id uuid NOT NULL,
  proposed_content text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  rejection_reason text,
  resolved_by uuid,
  resolved_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT project_section_edit_requests_pkey PRIMARY KEY (id),
  CONSTRAINT psr_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT psr_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES public.profiles(id),
  CONSTRAINT psr_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id)
);

CREATE INDEX IF NOT EXISTS project_section_edit_requests_lookup_idx
  ON public.project_section_edit_requests (project_id, section_key, status);
