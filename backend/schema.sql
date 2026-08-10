-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

DROP TABLE IF EXISTS public.project_papers CASCADE;
DROP TABLE IF EXISTS public.version CASCADE;
DROP TABLE IF EXISTS public.collaboration_requests CASCADE;
DROP TABLE IF EXISTS public.project_members CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  avatar_url text,
  university text,
  role text,
  created_at timestamp without time zone,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid,
  title text DEFAULT ''::text,
  description text DEFAULT ''::text,
  status text DEFAULT ''::text,
  progress numeric,
  start_date date,
  deadline date,
  latest_summary jsonb,
  latest_comparison jsonb,
  latest_research_gap jsonb,
  latest_literature_review jsonb,
  latest_papers jsonb,
  search_status text NOT NULL DEFAULT 'pending',
  search_errors jsonb NOT NULL DEFAULT '[]'::jsonb,
  search_queries jsonb NOT NULL DEFAULT '[]'::jsonb,
  search_paper_count integer,
  current_version_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT projects_pkey PRIMARY KEY (id),
  CONSTRAINT projects_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id),
  CONSTRAINT projects_current_version_id_fkey FOREIGN KEY (current_version_id) REFERENCES public.version(id)
);
CREATE TABLE public.project_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid,
  user_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  member_role text,
  joined_at timestamp without time zone,
  CONSTRAINT project_members_pkey PRIMARY KEY (id),
  CONSTRAINT project_members_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT project_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.collaboration_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid,
  requested_by uuid,
  requested_to uuid,
  message text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT collaboration_requests_pkey PRIMARY KEY (id),
  CONSTRAINT collaboration_requests_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT collaboration_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.profiles(id),
  CONSTRAINT collaboration_requests_requested_to_fkey FOREIGN KEY (requested_to) REFERENCES public.profiles(id)
);
CREATE TABLE public.version (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid,
  created_by uuid,
  snapshot_name text,
  summary jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  version_message text,
  is_current boolean,
  comparison jsonb,
  research_gap jsonb,
  literature_review jsonb NOT NULL,
  papers jsonb,
  CONSTRAINT version_pkey PRIMARY KEY (id),
  CONSTRAINT ai_outputs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT ai_outputs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.project_papers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  project_id uuid,
  title text,
  authors text,
  abstract text,
  year numeric,
  fetched_at timestamp with time zone NOT NULL DEFAULT now(),
  doi text,
  paper_url text,
  doi_url text,
  pdf_url text,
  citations smallint,
  is_selected boolean,
  CONSTRAINT project_papers_pkey PRIMARY KEY (id),
  CONSTRAINT project_papers_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id)
);