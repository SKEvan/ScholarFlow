-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  full_name text,
  avatar_url text,
  university text,
  role text,
  created_at timestamp without time zone,
  CONSTRAINT profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.projects (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  owner_id bigint,
  title text DEFAULT ''::text,
  description text DEFAULT ''::text,
  status text DEFAULT ''::text,
  progress numeric,
  start_date date,
  deadline date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT projects_pkey PRIMARY KEY (id),
  CONSTRAINT projects_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.project_members (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  project_id bigint,
  user_id bigint,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  member_role text,
  joined_at timestamp without time zone,
  CONSTRAINT project_members_pkey PRIMARY KEY (id),
  CONSTRAINT project_members_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT project_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.collaboration_requests (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  project_id bigint,
  requested_by bigint,
  requested_to bigint,
  message text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT collaboration_requests_pkey PRIMARY KEY (id),
  CONSTRAINT collaboration_requests_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id),
  CONSTRAINT collaboration_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.profiles(id),
  CONSTRAINT collaboration_requests_requested_to_fkey FOREIGN KEY (requested_to) REFERENCES public.profiles(id)
);
CREATE TABLE public.version (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  project_id bigint,
  created_by bigint,
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
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  project_id bigint,
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
  CONSTRAINT project_papers_pkey PRIMARY KEY (id),
  CONSTRAINT project_papers_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id)
);