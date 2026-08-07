from __future__ import annotations

import os
from typing import Any, Dict, Iterable, List, Optional

import requests


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

    def list_projects(self) -> List[Dict[str, Any]]:
        result = self._request("GET", "projects", params={"select": "*", "order": "created_at.desc"})
        return result if isinstance(result, list) else []

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


supabase_service = SupabaseService()