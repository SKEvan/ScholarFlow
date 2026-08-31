from __future__ import annotations

import os
import secrets
from datetime import datetime, timezone
from typing import Any, Dict, Iterable, List, Optional

import requests


def _utcnow_iso() -> str:
    """ISO-8601 UTC timestamp with 'Z' suffix, suitable for timestamptz cols."""
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


class SupabaseError(RuntimeError):
    pass


def _normalize_base_url(raw_url: str) -> str:
    base = raw_url.rstrip("/")
    if not base:
        return ""
    if base.endswith("/rest/v1"):
        return base
    return f"{base}/rest/v1"


def _normalize_project_url(raw_url: str) -> str:
    base = raw_url.rstrip("/")
    if not base:
        return ""
    if base.endswith("/rest/v1"):
        return base[: -len("/rest/v1")]
    return base


class SupabaseService:
    def __init__(self) -> None:
        self.base_url = _normalize_base_url(os.getenv("SUPABASE_URL", ""))
        self.project_url = _normalize_project_url(os.getenv("SUPABASE_URL", ""))
        self.api_key = os.getenv("SUPABASE_API_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY") or ""

    def is_configured(self) -> bool:
        return bool(self.base_url and self.api_key)

    def is_auth_configured(self) -> bool:
        return bool(self.project_url and self.api_key)

    def _headers(self) -> Dict[str, str]:
        if not self.is_configured():
            raise SupabaseError("Supabase is not configured. Set SUPABASE_URL and SUPABASE_API_KEY.")
        return {
            "apikey": self.api_key,
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    def _auth_headers(self) -> Dict[str, str]:
        if not self.is_auth_configured():
            raise SupabaseError("Supabase auth is not configured. Set SUPABASE_URL and SUPABASE_API_KEY.")
        return {
            "apikey": self.api_key,
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json_body: Any = None,
        prefer: Optional[str] = None,
    ) -> Any:
        url = f"{self.base_url}/{path.lstrip('/')}"
        headers = self._headers()
        if prefer:
            headers["Prefer"] = prefer
        response = requests.request(
            method,
            url,
            headers=headers,
            params=params,
            json=json_body,
            timeout=30,
        )
        if response.status_code >= 400:
            raise SupabaseError(f"Supabase request failed ({response.status_code}): {response.text}")
        if not response.text:
            return []
        return response.json()

    def _auth_request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json_body: Any = None,
    ) -> Any:
        url = f"{self.project_url}/{path.lstrip('/')}"
        response = requests.request(
            method,
            url,
            headers=self._auth_headers(),
            params=params,
            json=json_body,
            timeout=30,
        )
        if response.status_code >= 400:
            raise SupabaseError(f"Supabase auth request failed ({response.status_code}): {response.text}")
        if not response.text:
            return {}
        return response.json()

    @staticmethod
    def _single(items: Any) -> Dict[str, Any]:
        if isinstance(items, list):
            return items[0] if items else {}
        if isinstance(items, dict):
            return items
        return {}

    @staticmethod
    def _list(value: Optional[Iterable[Any]]) -> List[Any]:
        return list(value or [])

    # ------------------------------------------------------------------ #
    # Projects
    # ------------------------------------------------------------------ #

    def create_project(
        self,
        title: str,
        description: str = "",
        status: str = "active",
        start_date: Optional[str] = None,
        deadline: Optional[str] = None,
        owner_id: Optional[str] = None,        # UUID → str
    ) -> Dict[str, Any]:
        payload: Dict[str, Any] = {"title": title, "description": description, "status": status}
        if start_date:
            payload["start_date"] = start_date
        if deadline:
            payload["deadline"] = deadline
        if owner_id is not None:
            payload["owner_id"] = owner_id
        result = self._request("POST", "projects", json_body=payload)
        return self._single(result)

    def list_projects(self, owner_id: Optional[str] = None) -> List[Dict[str, Any]]:
        params: Dict[str, Any] = {"select": "*", "order": "created_at.desc"}
        if owner_id:
            # A user can see a project either because they own it, or because
            # they're a row in `project_members`. PostgREST's `or=` filter
            # supports both, but `project_members.project_id` references
            # projects.id, so the right side is `id.in.(...)` of project ids
            # the user belongs to.
            member_rows = self._request(
                "GET",
                "project_members",
                params={
                    "user_id": f"eq.{owner_id}",
                    "select": "project_id",
                },
            )
            member_project_ids: List[str] = []
            for row in (member_rows if isinstance(member_rows, list) else []):
                pid = row.get("project_id")
                if pid:
                    member_project_ids.append(pid)
            clauses = [f"owner_id.eq.{owner_id}"]
            if member_project_ids:
                # PostgREST `in.` filter expects a parenthesised CSV.
                ids_csv = ",".join(member_project_ids)
                clauses.append(f"id.in.({ids_csv})")
            params["or"] = f"({','.join(clauses)})"
        result = self._request("GET", "projects", params=params)
        projects = result if isinstance(result, list) else []
        if not projects:
            return projects

        # Collect all project ids for bulk count queries (avoids N+1 per project).
        project_ids = [p["id"] for p in projects if p.get("id")]
        id_list = ",".join(project_ids)

        # Paper counts.
        paper_rows = self._request(
            "GET",
            "project_papers",
            params={"project_id": f"in.({id_list})", "citations": "gt.0", "select": "project_id"},
        )
        paper_counts: Dict[str, int] = {}
        for row in (paper_rows if isinstance(paper_rows, list) else []):
            pid = row.get("project_id")
            if pid:
                paper_counts[pid] = paper_counts.get(pid, 0) + 1

        # Version counts.
        version_rows = self._request(
            "GET",
            "version",
            params={"project_id": f"in.({id_list})", "select": "project_id"},
        )
        version_counts: Dict[str, int] = {}
        for row in (version_rows if isinstance(version_rows, list) else []):
            pid = row.get("project_id")
            if pid:
                version_counts[pid] = version_counts.get(pid, 0) + 1

        # Stitch counts into each project dict.
        for project in projects:
            pid = project.get("id")
            project["paper_count"] = paper_counts.get(pid, 0)
            project["version_count"] = version_counts.get(pid, 0)

        return projects

    def get_project(self, project_id: str) -> Dict[str, Any]:    # UUID → str
        result = self._request("GET", "projects", params={"id": f"eq.{project_id}", "select": "*"})
        return self._single(result)

    def update_project(self, project_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:   # UUID → str
        result = self._request(
            "PATCH",
            "projects",
            params={"id": f"eq.{project_id}"},
            json_body=updates,
        )
        return self._single(result)

    # ------------------------------------------------------------------ #
    # Collaboration
    # ------------------------------------------------------------------ #

    def create_collaboration_requests(
        self,
        project_id: str,                        # UUID → str (was int)
        collaborators: List[str],
        requested_by: Optional[str] = None,     # UUID → str
    ) -> List[Dict[str, Any]]:
        rows: List[Dict[str, Any]] = []
        for collaborator in collaborators:
            cleaned = str(collaborator).strip()
            if not cleaned:
                continue
            rows.append(
                {
                    "project_id": project_id,
                    "requested_by": requested_by,
                    "message": f"Invite collaborator: {cleaned}",
                }
            )
        if not rows:
            return []
        result = self._request("POST", "collaboration_requests", json_body=rows)
        return result if isinstance(result, list) else [result]

    # ------------------------------------------------------------------ #
    # Project Members
    # ------------------------------------------------------------------ #

    _VALID_MEMBER_ROLES = ("viewer", "editor", "lead")

    def list_project_members(self, project_id: str) -> List[Dict[str, Any]]:
        # UUID → str. Joins each member's profile so the UI can render the
        # avatar/name without a second round-trip.
        result = self._request(
            "GET",
            "project_members",
            params={
                "project_id": f"eq.{project_id}",
                "select": "id,project_id,user_id,member_role,joined_at,created_at,"
                          "profiles:user_id(id,full_name,avatar_url,university,role)",
                "order": "joined_at.asc",
            },
        )
        return result if isinstance(result, list) else []

    def add_project_member(
        self,
        project_id: str,                          # UUID → str
        user_id: str,                             # UUID → str
        role: str,
    ) -> Dict[str, Any]:
        normalized = (role or "").strip().lower()
        if normalized not in self._VALID_MEMBER_ROLES:
            raise ValueError(
                f"Invalid role '{role}'. Expected one of {self._VALID_MEMBER_ROLES}."
            )
        payload = {
            "project_id": project_id,
            "user_id": user_id,
            "member_role": normalized,
        }
        result = self._request(
            "POST",
            "project_members",
            params={"select": "id,project_id,user_id,member_role,joined_at,created_at,"
                              "profiles:user_id(id,full_name,avatar_url,university,role)"},
            json_body=payload,
        )
        return self._single(result)

    def update_project_member_role(
        self,
        member_id: str,                          # UUID → str
        role: str,
    ) -> Dict[str, Any]:
        normalized = (role or "").strip().lower()
        if normalized not in self._VALID_MEMBER_ROLES:
            raise ValueError(
                f"Invalid role '{role}'. Expected one of {self._VALID_MEMBER_ROLES}."
            )
        result = self._request(
            "PATCH",
            "project_members",
            params={
                "id": f"eq.{member_id}",
                "select": "id,project_id,user_id,member_role,joined_at,created_at,"
                          "profiles:user_id(id,full_name,avatar_url,university,role)",
            },
            json_body={"member_role": normalized},
        )
        return self._single(result)

    def remove_project_member(self, member_id: str) -> None:    # UUID → str
        self._request(
            "DELETE",
            "project_members",
            params={"id": f"eq.{member_id}"},
        )

    # ------------------------------------------------------------------ #
    # Invitations (collaboration_requests)
    # ------------------------------------------------------------------ #
    #
    # Backed by the existing `collaboration_requests` table, extended with
    # role/email/status/token columns. Existing rows are untouched. The
    # legacy `create_collaboration_requests` helper above is preserved for
    # any code path that still uses it (project research flow).

    _VALID_INVITE_STATUSES = ("pending", "accepted", "declined", "revoked")
    # NOTE: `profiles` table does not have an `email` column (email lives in
    # auth.users). The invitee's email is already on collaboration_requests.email,
    # so the invited_user embed only pulls name/avatar from profiles.
    _INVITATION_SELECT = (
        "id,project_id,requested_by,requested_to,role,email,status,token,"
        "message,created_at,responded_at,accepted_by,"
        "projects:project_id(id,title,owner_id),"
        "profiles:requested_by(id,full_name,avatar_url,university),"
        "invited_user:requested_to(id,full_name,avatar_url,university)"
    )

    def _generate_invite_token(self) -> str:
        # 32 url-safe bytes ≈ 43 chars. Plenty of entropy and safe to share
        # in a URL fragment / query string.
        return secrets.token_urlsafe(32)

    def _normalize_role(self, role: str) -> str:
        normalized = (role or "").strip().lower()
        if normalized not in self._VALID_MEMBER_ROLES:
            raise ValueError(
                f"Invalid role '{role}'. Expected one of {self._VALID_MEMBER_ROLES}."
            )
        return normalized

    def list_invitations(
        self,
        project_id: Optional[str] = None,
        status: Optional[str] = None,
        email: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        params: Dict[str, Any] = {
            "select": self._INVITATION_SELECT,
            "order": "created_at.desc",
        }
        if project_id:
            params["project_id"] = f"eq.{project_id}"
        if status:
            normalized = (status or "").strip().lower()
            if normalized not in self._VALID_INVITE_STATUSES:
                raise ValueError(
                    f"Invalid status '{status}'. "
                    f"Expected one of {self._VALID_INVITE_STATUSES}."
                )
            params["status"] = f"eq.{normalized}"
        if email:
            params["email"] = f"ilike.{email.strip().lower()}"
        result = self._request("GET", "collaboration_requests", params=params)
        return result if isinstance(result, list) else []

    def get_invitation_by_token(self, token: str) -> Optional[Dict[str, Any]]:
        if not token:
            return None
        result = self._request(
            "GET",
            "collaboration_requests",
            params={
                "token": f"eq.{token}",
                "select": self._INVITATION_SELECT,
                "limit": "1",
            },
        )
        if isinstance(result, list):
            return result[0] if result else None
        return result if isinstance(result, dict) else None

    def create_invitation(
        self,
        project_id: str,
        email: str,
        role: str,
        invited_by: Optional[str] = None,
        message: Optional[str] = None,
        token: Optional[str] = None,
    ) -> Dict[str, Any]:
        clean_email = (email or "").strip().lower()
        if not clean_email or "@" not in clean_email:
            raise ValueError("A valid invitee email is required.")
        normalized_role = self._normalize_role(role)
        payload: Dict[str, Any] = {
            "project_id": project_id,
            "email": clean_email,
            "role": normalized_role,
            "status": "pending",
            "token": token or self._generate_invite_token(),
            "message": (message or "").strip() or f"Invite collaborator: {clean_email}",
        }
        if invited_by:
            payload["requested_by"] = invited_by
        result = self._request(
            "POST",
            "collaboration_requests",
            params={"select": self._INVITATION_SELECT},
            json_body=payload,
        )
        return self._single(result)

    def accept_invitation(
        self,
        token: str,
        accepting_user_id: str,
    ) -> Dict[str, Any]:
        invitation = self.get_invitation_by_token(token)
        if not invitation:
            raise ValueError("Invitation not found.")
        if (invitation.get("status") or "").lower() != "pending":
            raise ValueError(
                f"Invitation is already {invitation.get('status') or 'used'}."
            )
        project_id = invitation.get("project_id")
        role = (invitation.get("role") or "viewer").lower()
        if not project_id:
            raise ValueError("Invitation is missing a project reference.")

        # Flip the invitation to accepted first so a failed member insert
        # leaves the audit row in a recoverable state.
        updated = self._request(
            "PATCH",
            "collaboration_requests",
            params={
                "id": f"eq.{invitation['id']}",
                "select": self._INVITATION_SELECT,
            },
            json_body={
                "status": "accepted",
                "responded_at": _utcnow_iso(),
                "accepted_by": accepting_user_id,
            },
        )
        try:
            self.add_project_member(project_id, accepting_user_id, role)
        except Exception:
            # Revert the status so the user can retry instead of being stuck.
            self._request(
                "PATCH",
                "collaboration_requests",
                params={
                    "id": f"eq.{invitation['id']}",
                    "select": self._INVITATION_SELECT,
                },
                json_body={"status": "pending", "accepted_by": None},
            )
            raise
        return self._single(updated)

    def decline_invitation(self, token: str) -> Dict[str, Any]:
        invitation = self.get_invitation_by_token(token)
        if not invitation:
            raise ValueError("Invitation not found.")
        if (invitation.get("status") or "").lower() != "pending":
            raise ValueError(
                f"Invitation is already {invitation.get('status') or 'used'}."
            )
        result = self._request(
            "PATCH",
            "collaboration_requests",
            params={
                "id": f"eq.{invitation['id']}",
                "select": self._INVITATION_SELECT,
            },
            json_body={"status": "declined", "responded_at": _utcnow_iso()},
        )
        return self._single(result)

    def revoke_invitation(self, invitation_id: str) -> None:
        self._request(
            "PATCH",
            "collaboration_requests",
            params={"id": f"eq.{invitation_id}"},
            json_body={"status": "revoked", "responded_at": _utcnow_iso()},
        )

    # ------------------------------------------------------------------ #
    # Papers
    # ------------------------------------------------------------------ #

    def upsert_project_papers(self, project_id: str, papers: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        # UUID → str (was int). Uses POST with on_conflict to avoid duplicates.
        rows: List[Dict[str, Any]] = []
        for paper in papers:
            rows.append(
                {
                    "project_id": project_id,
                    "title": paper.get("title") or "",
                    "authors": ", ".join(self._list(paper.get("authors"))),
                    "abstract": paper.get("abstract"),
                    "year": paper.get("year"),
                    "doi": paper.get("doi"),
                    "paper_url": paper.get("paper_url"),
                    "doi_url": paper.get("doi_url"),
                    "pdf_url": paper.get("pdf_url"),
                    "citations": paper.get("citations") or 0,
                    "is_selected": True,
                }
            )
        if not rows:
            return []
        # on_conflict prevents duplicate rows when the same paper is saved twice.
        # Adjust the conflict column(s) to match your DB unique constraint
        # (e.g. "project_id,doi" or "project_id,title").
        result = self._request(
            "POST",
            "project_papers",
            json_body=rows,
            prefer="resolution=merge-duplicates,return=representation",
        )
        return result if isinstance(result, list) else [result]

    def list_project_papers(self, project_id: str, selected_only: bool = False) -> List[Dict[str, Any]]:
        # UUID → str
        params: Dict[str, Any] = {
            "project_id": f"eq.{project_id}",
            "select": "*",
            "order": "citations.desc",
        }
        if selected_only:
            params["is_selected"] = "eq.true"
        result = self._request("GET", "project_papers", params=params)
        return result if isinstance(result, list) else []

    def list_dashboard_papers(self, user_id: str) -> List[Dict[str, Any]]:
        """Every research paper across the user's accessible projects
        (owned + membered). Each paper is annotated with its project_id
        and project_title so the dashboard can group by project.
        """
        if not user_id:
            return []
        # 1. Resolve the visible project set.
        projects = self.list_projects(owner_id=user_id) or []
        project_ids: List[str] = [str(p.get("id")) for p in projects if p.get("id")]
        if not project_ids:
            return []
        id_list = ",".join(project_ids)
        # 2. Pull all papers for those projects, most-cited first.
        papers = self._request(
            "GET",
            "project_papers",
            params={
                "project_id": f"in.({id_list})",
                "select": "*",
                "order": "citations.desc",
            },
        )
        if not isinstance(papers, list):
            return []
        # 3. Annotate with project title for the UI.
        title_by_id = {str(p.get("id")): p.get("title", "") for p in projects}
        for paper in papers:
            pid = paper.get("project_id")
            if pid is not None:
                paper["project_title"] = title_by_id.get(str(pid), "")
        return papers

    def set_project_papers_selection(self, project_id: str, selected_ids: List[str]) -> None:
        # UUID → str for both project_id and selected_ids (was List[int])
        self._request(
            "PATCH",
            "project_papers",
            params={"project_id": f"eq.{project_id}"},
            json_body={"is_selected": False},
        )
        if selected_ids:
            id_list = ",".join(selected_ids)   # UUID strings — no int() cast
            self._request(
                "PATCH",
                "project_papers",
                params={
                    "project_id": f"eq.{project_id}",
                    "id": f"in.({id_list})",
                },
                json_body={"is_selected": True},
            )

    def update_project_latest_outputs(self, project_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        return self.update_project(project_id, updates)

    # ------------------------------------------------------------------ #
    # Versions
    # ------------------------------------------------------------------ #

    def insert_version(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        result = self._request("POST", "version", json_body=payload)
        return self._single(result)

    def list_versions(self, project_id: str) -> List[Dict[str, Any]]:   # UUID → str
        result = self._request(
            "GET",
            "version",
            params={"project_id": f"eq.{project_id}", "order": "created_at.desc"},
        )
        return result if isinstance(result, list) else []

    def get_version(self, version_id: str) -> Dict[str, Any]:           # UUID → str
        result = self._request("GET", "version", params={"id": f"eq.{version_id}", "select": "*"})
        return self._single(result)

    def set_current_version(self, project_id: str, version_id: str) -> None:  # UUID → str
        self._request(
            "PATCH",
            "version",
            params={"project_id": f"eq.{project_id}"},
            json_body={"is_current": False},
        )
        self._request(
            "PATCH",
            "version",
            params={"id": f"eq.{version_id}"},
            json_body={"is_current": True},
        )

    # ------------------------------------------------------------------ #
    # Project Sections (Abstract / Introduction / Literature Review / Methodology)
    # ------------------------------------------------------------------ #

    _SECTION_KEYS = ("abstract", "introduction", "literature_review", "methodology")
    _SECTION_SELECT = (
        "id,project_id,section_key,owner_user_id,approved_content,approved_by,"
        "updated_at,created_at,"
        "owner:owner_user_id(id,full_name,avatar_url),"
        "approver:approved_by(id,full_name,avatar_url)"
    )
    _EDIT_REQUEST_SELECT = (
        "id,project_id,section_key,author_user_id,proposed_content,status,"
        "rejection_reason,resolved_by,resolved_at,created_at,updated_at,"
        "author:author_user_id(id,full_name,avatar_url),"
        "resolver:resolved_by(id,full_name,avatar_url)"
    )

    def _default_section(self, project_id: str, section_key: str) -> Dict[str, Any]:
        # Synthesized placeholder for a section that hasn't been touched
        # yet — no row is created until an owner is assigned or content
        # is saved, so list/get calls stay correct without provisioning.
        return {
            "id": None,
            "project_id": project_id,
            "section_key": section_key,
            "owner_user_id": None,
            "owner": None,
            "approved_content": "",
            "approved_by": None,
            "approver": None,
            "updated_at": None,
            "created_at": None,
        }

    def list_project_sections(self, project_id: str) -> List[Dict[str, Any]]:   # UUID → str
        result = self._request(
            "GET",
            "project_sections",
            params={"project_id": f"eq.{project_id}", "select": self._SECTION_SELECT},
        )
        rows = result if isinstance(result, list) else []
        by_key = {row["section_key"]: row for row in rows if row.get("section_key")}
        return [
            by_key.get(key) or self._default_section(project_id, key)
            for key in self._SECTION_KEYS
        ]

    def get_project_section(self, project_id: str, section_key: str) -> Dict[str, Any]:   # UUID → str
        result = self._request(
            "GET",
            "project_sections",
            params={
                "project_id": f"eq.{project_id}",
                "section_key": f"eq.{section_key}",
                "select": self._SECTION_SELECT,
            },
        )
        row = self._single(result)
        return row or self._default_section(project_id, section_key)

    def _upsert_section(
        self, project_id: str, section_key: str, updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        # POST with on_conflict + merge-duplicates upserts the (project_id,
        # section_key) row: creates it on first touch, otherwise patches
        # only the given columns — same pattern as sign_up_user's profile
        # upsert below.
        payload = {"project_id": project_id, "section_key": section_key, **updates}
        result = self._request(
            "POST",
            "project_sections",
            params={
                "on_conflict": "project_id,section_key",
                "select": self._SECTION_SELECT,
            },
            json_body=payload,
            prefer="resolution=merge-duplicates,return=representation",
        )
        return self._single(result)

    def set_section_owner(
        self, project_id: str, section_key: str, owner_user_id: str
    ) -> Dict[str, Any]:
        return self._upsert_section(project_id, section_key, {"owner_user_id": owner_user_id})

    def update_section_content(
        self, project_id: str, section_key: str, content: str, actor_user_id: str
    ) -> Dict[str, Any]:
        return self._upsert_section(
            project_id,
            section_key,
            {
                "approved_content": content,
                "approved_by": actor_user_id,
                "updated_at": _utcnow_iso(),
            },
        )

    def create_section_edit_request(
        self, project_id: str, section_key: str, author_user_id: str, content: str
    ) -> Dict[str, Any]:
        payload = {
            "project_id": project_id,
            "section_key": section_key,
            "author_user_id": author_user_id,
            "proposed_content": content,
            "status": "pending",
        }
        result = self._request(
            "POST",
            "project_section_edit_requests",
            params={"select": self._EDIT_REQUEST_SELECT},
            json_body=payload,
        )
        return self._single(result)

    def list_section_edit_requests(
        self, project_id: str, section_key: str, status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        params: Dict[str, Any] = {
            "project_id": f"eq.{project_id}",
            "section_key": f"eq.{section_key}",
            "select": self._EDIT_REQUEST_SELECT,
            "order": "created_at.desc",
        }
        if status:
            params["status"] = f"eq.{status}"
        result = self._request("GET", "project_section_edit_requests", params=params)
        return result if isinstance(result, list) else []

    def get_section_edit_request(self, request_id: str) -> Dict[str, Any]:   # UUID → str
        result = self._request(
            "GET",
            "project_section_edit_requests",
            params={"id": f"eq.{request_id}", "select": self._EDIT_REQUEST_SELECT},
        )
        return self._single(result)

    def resolve_section_edit_request(
        self,
        request_id: str,
        status: str,
        resolved_by: str,
        rejection_reason: Optional[str] = None,
    ) -> Dict[str, Any]:
        updates: Dict[str, Any] = {
            "status": status,
            "resolved_by": resolved_by,
            "resolved_at": _utcnow_iso(),
            "updated_at": _utcnow_iso(),
        }
        if rejection_reason is not None:
            updates["rejection_reason"] = rejection_reason
        result = self._request(
            "PATCH",
            "project_section_edit_requests",
            params={"id": f"eq.{request_id}", "select": self._EDIT_REQUEST_SELECT},
            json_body=updates,
        )
        return self._single(result)

    # ------------------------------------------------------------------ #
    # Auth
    # ------------------------------------------------------------------ #

    def sign_up_user(
        self,
        *,
        email: str,
        password: str,
        full_name: str = "",
        avatar_url: str = "",
        university: str = "",
        role: str = "",
    ) -> Dict[str, Any]:
        auth_result = self._auth_request(
            "POST",
            "auth/v1/signup",
            json_body={
                "email": email,
                "password": password,
                "options": {
                    "data": {
                        "full_name": full_name,
                        "avatar_url": avatar_url,
                        "university": university,
                        "role": role,
                    }
                },
            },
        )
        user = (auth_result or {}).get("user") or {}
        if user.get("id"):
            self._request(
                "POST",
                "profiles",
                params={"on_conflict": "id"},
                json_body={
                    "id": user.get("id"),
                    "full_name": full_name or None,
                    "avatar_url": avatar_url or None,
                    "university": university or None,
                    "role": role or None,
                },
                prefer="resolution=merge-duplicates,return=representation",
            )
        return {
            "user": user,
            # sign_up returns session nested under "session" key — correct
            "session": auth_result.get("session") if isinstance(auth_result, dict) else None,
            "profile": {
                "id": user.get("id"),
                "full_name": full_name or None,
                "avatar_url": avatar_url or None,
                "university": university or None,
                "role": role or None,
            },
        }

    def sign_in_user(self, *, email: str, password: str) -> Dict[str, Any]:
        auth_result = self._auth_request(
            "POST",
            "auth/v1/token",
            params={"grant_type": "password"},
            json_body={
                "email": email,
                "password": password,
            },
        )
        # FIX: Supabase /auth/v1/token returns the session fields at the TOP
        # LEVEL of the response (access_token, refresh_token, token_type,
        # expires_in, expires_at), NOT nested under a "session" key.
        # Previously this always returned session=None.
        user = (auth_result or {}).get("user") or {}
        session = None
        if isinstance(auth_result, dict) and auth_result.get("access_token"):
            session = {
                "access_token": auth_result.get("access_token"),
                "refresh_token": auth_result.get("refresh_token"),
                "token_type": auth_result.get("token_type"),
                "expires_in": auth_result.get("expires_in"),
                "expires_at": auth_result.get("expires_at"),
            }

        profile: Dict[str, Any] = {}
        if user.get("id"):
            result = self._request(
                "GET",
                "profiles",
                params={"id": f"eq.{user.get('id')}", "select": "*"},
            )
            profile = self._single(result)

        return {
            "user": user,
            "session": session,
            "profile": profile,
        }

    # ------------------------------------------------------------------ #
    # Profiles
    # ------------------------------------------------------------------ #

    def get_profile(self, user_id: str) -> Dict[str, Any]:
        result = self._request("GET", "profiles", params={"id": f"eq.{user_id}", "select": "*"})
        return self._single(result)

    def upsert_profile(self, user_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        row = {"id": user_id}
        row.update(payload)
        result = self._request(
            "POST",
            "profiles",
            params={"on_conflict": "id"},
            json_body=row,
            prefer="resolution=merge-duplicates,return=representation",
        )
        return self._single(result)

    @staticmethod
    def profile_missing_fields(profile: Dict[str, Any]) -> list[str]:
        required_fields = ["full_name", "university", "role"]
        missing = []
        for field in required_fields:
            value = str(profile.get(field) or "").strip()
            if not value:
                missing.append(field)
        return missing

    # ------------------------------------------------------------------ #
    # Profile stats
    # ------------------------------------------------------------------ #

    def get_profile_stats(self, user_id: str) -> Dict[str, Any]:
        """Aggregate stats for the profile screen.

        Returns citations_total (sum of project_papers.citations for every
        project the user owns or is a member of), h_index (the largest N
        such that the user has N papers with >= N citations each), and
        recent_projects (up to 5 most recently created projects owned or
        membered, with paper + citation counts).
        """
        if not user_id:
            return {
                "user_id": user_id,
                "citations_total": 0,
                "papers_total": 0,
                "h_index": 0,
                "recent_projects": [],
                "owned_projects": 0,
                "member_projects": 0,
            }

        # 1. Collect every project the user can see (owned + membered).
        projects = self.list_projects(owner_id=user_id) or []
        project_ids: List[str] = [str(p.get("id")) for p in projects if p.get("id")]
        owned_count = 0
        member_count = 0
        for project in projects:
            owner_id_val = project.get("owner_id")
            if owner_id_val and str(owner_id_val) == str(user_id):
                owned_count += 1
            else:
                member_count += 1

        # 2. Sum citation counts from project_papers.
        citations_total = 0
        papers_total = 0
        citation_per_paper: List[int] = []
        if project_ids:
            id_list = ",".join(project_ids)
            paper_rows = self._request(
                "GET",
                "project_papers",
                params={
                    "project_id": f"in.({id_list})",
                    "select": "citations",
                },
            )
            for row in (paper_rows if isinstance(paper_rows, list) else []):
                cit_raw = row.get("citations")
                try:
                    cit_val = int(cit_raw or 0)
                except (TypeError, ValueError):
                    cit_val = 0
                citation_per_paper.append(cit_val)
                citations_total += cit_val
                papers_total += 1

        # 3. H-index: largest N such that >= N papers have >= N citations.
        citation_per_paper.sort(reverse=True)
        h_index = 0
        for idx, cit in enumerate(citation_per_paper, start=1):
            if cit >= idx:
                h_index = idx
            else:
                break

        # 4. Recent projects: already ordered by created_at.desc from
        # list_projects; cap at 5. Each entry includes paper_count and
        # citation sum for that single project.
        recent: List[Dict[str, Any]] = []
        for project in projects[:5]:
            pid = project.get("id")
            entry = {
                "id": pid,
                "title": project.get("title"),
                "status": project.get("status"),
                "owner_id": project.get("owner_id"),
                "created_at": project.get("created_at"),
                "updated_at": project.get("updated_at"),
                "paper_count": project.get("paper_count", 0),
                "version_count": project.get("version_count", 0),
            }
            recent.append(entry)

        return {
            "user_id": user_id,
            "citations_total": citations_total,
            "papers_total": papers_total,
            "h_index": h_index,
            "recent_projects": recent,
            "owned_projects": owned_count,
            "member_projects": member_count,
        }


supabase_service = SupabaseService()