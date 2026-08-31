from datetime import datetime, timezone
import json
import logging
from pathlib import Path
import sys
from typing import Dict, Optional

from fastapi import Body, FastAPI
from fastapi import HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from pydantic import BaseModel, Field

BASE_DIR = Path(__file__).resolve().parent
AGENTS_DIR = BASE_DIR / "agents"
for path in (BASE_DIR, AGENTS_DIR):
    path_text = str(path)
    if path_text not in sys.path:
        sys.path.insert(0, path_text)

# Load .env BEFORE importing anything that reads env vars at module-import time
# (e.g. supabase_service instantiates SupabaseService() at module load, which
# reads os.getenv("SUPABASE_URL") / os.getenv("SUPABASE_API_KEY")).
load_dotenv(BASE_DIR / ".env")
load_dotenv(AGENTS_DIR / ".env")

from supabase_service import SupabaseError
from supabase_service import supabase_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="ScholarFlow Backend", version="0.1.0")

# Allow Flutter web (Chrome) and any other origin to call the API.
# In production you can tighten this to your actual web domain.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins; restrict if needed
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AbstractItem(BaseModel):
    title: str | None = None
    abstract: str


class AgentRequest(BaseModel):
    abstracts: list[AbstractItem] = Field(default_factory=list)
    desired_output_type: str = Field(default="")
    project_id: str | None = None           # UUID → str
    selected_paper_ids: list[str] = Field(default_factory=list)  # UUID → str
    user_prompt: str = Field(default="")


class ProjectResearchRequest(BaseModel):
    title: str
    description: str = Field(default="")
    status: str = Field(default="active")
    start_date: str | None = None
    deadline: str | None = None
    desired_output_type: str = Field(default="")
    owner_id: str | None = None             # UUID → str
    collaborators: list[str] = Field(default_factory=list)


class SaveVersionRequest(BaseModel):
    snapshot_name: str
    version_message: str = Field(default="")


class RestoreVersionRequest(BaseModel):
    version_id: str                         # UUID → str


class AddMemberRequest(BaseModel):
    user_id: str                             # UUID → str
    role: str = Field(default="editor")
    actor_user_id: str | None = None         # caller; must be the project owner


class UpdateMemberRoleRequest(BaseModel):
    role: str
    actor_user_id: str | None = None         # caller; must be the project owner


class CreateInvitationRequest(BaseModel):
    email: str
    role: str = Field(default="viewer")
    message: str = Field(default="")
    invited_by: str | None = None          # UUID → str
    actor_user_id: str | None = None         # caller; must be the project owner


class RevokeInvitationRequest(BaseModel):
    actor_user_id: str | None = None         # caller; must be the project owner


class LeaveProjectRequest(BaseModel):
    user_id: str                              # UUID → str of the leaver


class AcceptInvitationRequest(BaseModel):
    accepting_user_id: str                  # UUID → str


class SignUpRequest(BaseModel):
    email: str
    password: str
    full_name: str = Field(default="")
    avatar_url: str = Field(default="")
    university: str = Field(default="")
    role: str = Field(default="")


class SignInRequest(BaseModel):
    email: str
    password: str


class ProfileStatusRequest(BaseModel):
    user_id: str


class CompleteProfileRequest(BaseModel):
    user_id: str
    full_name: str = Field(default="")
    avatar_url: str = Field(default="")
    university: str = Field(default="")
    role: str = Field(default="")
    about: str = Field(default="")


def _load_project_abstracts(project_id: str, selected_paper_ids: list[str] | None = None) -> list[dict]:
    selected_ids = selected_paper_ids or []
    papers = supabase_service.list_project_papers(project_id, selected_only=bool(selected_ids))
    if selected_ids:
        selected_set = set(selected_ids)    # no int() cast — compare UUID strings directly
        papers = [paper for paper in papers if paper.get("id") in selected_set]
    elif not papers:
        papers = supabase_service.list_project_papers(project_id, selected_only=False)

    return [
        {
            "id": paper.get("id"),
            "title": paper.get("title"),
            "abstract": paper.get("abstract") or "",
            "authors": paper.get("authors"),
            "year": paper.get("year"),
            "citations": paper.get("citations") or 0,
        }
        for paper in papers
        if paper.get("abstract")
    ]


def _ensure_supabase() -> None:
    if not supabase_service.is_configured():
        raise HTTPException(
            status_code=500,
            detail="Supabase is not configured. Set SUPABASE_URL and SUPABASE_API_KEY.",
        )


@app.get("/")
def root() -> dict[str, str]:
    return {
        "message": "ScholarFlow backend is running.",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "message": "Backend is healthy.",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.post("/auth/signup")
def sign_up(payload: SignUpRequest) -> dict:
    email = payload.email.strip()
    password = payload.password
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    if not password.strip():
        raise HTTPException(status_code=400, detail="Password is required.")

    try:
        _ensure_supabase()
        return supabase_service.sign_up_user(
            email=email,
            password=password,
            full_name=payload.full_name.strip(),
            avatar_url=payload.avatar_url.strip(),
            university=payload.university.strip(),
            role=payload.role.strip(),
        )
    except SupabaseError as error:
        logger.exception("Sign up failed for %s", email)
        raise HTTPException(status_code=502, detail=str(error)) from error


@app.post("/auth/signin")
def sign_in(payload: SignInRequest) -> dict:
    email = payload.email.strip()
    password = payload.password
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    if not password.strip():
        raise HTTPException(status_code=400, detail="Password is required.")

    try:
        _ensure_supabase()
        return supabase_service.sign_in_user(email=email, password=password)
    except SupabaseError as error:
        logger.exception("Sign in failed for %s", email)
        raise HTTPException(status_code=502, detail=str(error)) from error


@app.post("/auth/profile-status")
def profile_status(payload: ProfileStatusRequest) -> dict:
    _ensure_supabase()
    profile = supabase_service.get_profile(payload.user_id)
    missing_fields = supabase_service.profile_missing_fields(profile)
    return {
        "profile": profile,
        "missing_fields": missing_fields,
        "is_complete": len(missing_fields) == 0,
    }


@app.get("/profiles/{user_id}")
def get_profile(user_id: str) -> dict:
    """GET profile fields for a user. Returns the row plus the list of
    required fields still missing (for the dashboard banner / profile
    completion flow)."""
    _ensure_supabase()
    profile = supabase_service.get_profile(user_id)
    missing_fields = supabase_service.profile_missing_fields(profile)
    return {
        "profile": profile,
        "missing_fields": missing_fields,
        "is_complete": len(missing_fields) == 0,
    }


@app.get("/profiles/{user_id}/stats")
def get_profile_stats(user_id: str) -> dict:
    """Aggregated stats for the profile screen: total citations, total
    papers, h-index, and the user's most recent projects (owned and
    membered)."""
    _ensure_supabase()
    stats = supabase_service.get_profile_stats(user_id)
    return stats


@app.get("/dashboard/research-papers")
def dashboard_research_papers(user_id: str) -> dict:
    """All research papers across the user's accessible projects
    (owned + membered), with project title attached. Used by the
    dashboard's expandable Research Papers section."""
    _ensure_supabase()
    papers = supabase_service.list_dashboard_papers(user_id)
    return {"papers": papers, "total": len(papers)}


@app.post("/auth/complete-profile")
def complete_profile(payload: CompleteProfileRequest) -> dict:
    _ensure_supabase()
    about_value = payload.about.strip()
    profile = supabase_service.upsert_profile(
        payload.user_id,
        {
            "full_name": payload.full_name.strip() or None,
            "avatar_url": payload.avatar_url.strip() or None,
            "university": payload.university.strip() or None,
            "role": payload.role.strip() or None,
            # Only persist `about` when the column exists in the DB.
            # Until migration 001 is applied the column is absent and
            # PostgREST would reject the upsert with an error, so we
            # omit the key for empty payloads and otherwise let the
            # service layer handle it (PostgREST will 400 if the column
            # is still missing -- callers can retry after running the
            # migration).
            **({"about": about_value} if about_value else {}),
        },
    )
    missing_fields = supabase_service.profile_missing_fields(profile)
    return {
        "profile": profile,
        "missing_fields": missing_fields,
        "is_complete": len(missing_fields) == 0,
    }


@app.post("/agents/summary")
def summary(payload: AgentRequest) -> dict:
    from Summary_Agent import run_summary_from_payload

    if payload.project_id is not None:
        _ensure_supabase()
        abstracts = _load_project_abstracts(payload.project_id, payload.selected_paper_ids)
        result = run_summary_from_payload(
            abstracts,
            desired_output_type=payload.desired_output_type or "General Summary",
            persist=False,
            user_prompt=payload.user_prompt,
        )
        supabase_service.update_project_latest_outputs(
            payload.project_id,
            {"latest_summary": result, "updated_at": datetime.now(timezone.utc).isoformat()},
        )
        return result

    return run_summary_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "General Summary",
        persist=True,
        user_prompt=payload.user_prompt,
    )


@app.post("/agents/comparison")
def comparison(payload: AgentRequest) -> dict:
    from Comparison_Agent import run_comparison_from_payload

    if payload.project_id is not None:
        _ensure_supabase()
        abstracts = _load_project_abstracts(payload.project_id, payload.selected_paper_ids)
        result = run_comparison_from_payload(
            abstracts,
            desired_output_type=payload.desired_output_type or "Overall Comparison",
            persist=False,
            user_prompt=payload.user_prompt,
        )
        supabase_service.update_project_latest_outputs(
            payload.project_id,
            {"latest_comparison": result, "updated_at": datetime.now(timezone.utc).isoformat()},
        )
        return result

    return run_comparison_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Overall Comparison",
        persist=True,
        user_prompt=payload.user_prompt,
    )


@app.post("/agents/research-gap")
def research_gap(payload: AgentRequest) -> dict:
    from Research_Gap_Agent import run_research_gap_from_payload

    if payload.project_id is not None:
        _ensure_supabase()
        abstracts = _load_project_abstracts(payload.project_id, payload.selected_paper_ids)
        result = run_research_gap_from_payload(
            abstracts,
            desired_output_type=payload.desired_output_type or "Research Gaps",
            persist=False,
            user_prompt=payload.user_prompt,
        )
        supabase_service.update_project_latest_outputs(
            payload.project_id,
            {"latest_research_gap": result, "updated_at": datetime.now(timezone.utc).isoformat()},
        )
        return result

    return run_research_gap_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Research Gaps",
        persist=True,
        user_prompt=payload.user_prompt,
    )


@app.post("/agents/literature-review")
def literature_review(payload: AgentRequest) -> dict:
    from Literature_Review_Agent import run_literature_review_from_payload

    if payload.project_id is not None:
        _ensure_supabase()
        abstracts = _load_project_abstracts(payload.project_id, payload.selected_paper_ids)
        result = run_literature_review_from_payload(
            abstracts,
            desired_output_type=payload.desired_output_type or "Narrative Review",
            persist=False,
            user_prompt=payload.user_prompt,
        )
        supabase_service.update_project_latest_outputs(
            payload.project_id,
            {"latest_literature_review": result, "updated_at": datetime.now(timezone.utc).isoformat()},
        )
        return result

    return run_literature_review_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Narrative Review",
        persist=True,
        user_prompt=payload.user_prompt,
    )


@app.post("/projects/research")
def research_project(payload: ProjectResearchRequest) -> dict:
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=400, detail="Project title is required.")

    _ensure_supabase()

    from Querry_Planning_Agent import generate_search_plan
    from Search_Agent import run_search_from_state
    from workflow_state import update_workflow_state, load_workflow_state

    project = supabase_service.create_project(
        title=title,
        description=payload.description,
        status=payload.status or "active",
        start_date=payload.start_date,
        deadline=payload.deadline,
        owner_id=payload.owner_id,
    )
    supabase_service.create_collaboration_requests(
        project["id"],                      # UUID string — no int() cast
        payload.collaborators,
        requested_by=payload.owner_id,
    )
    update_workflow_state(
        {
            "topic": title,
            "user_query": title,
            "desired_output_type": payload.desired_output_type or "",
            "current_agent": "project_research",
            "status": "project_research_started",
            "errors": [],
        }
    )

    plan = generate_search_plan(title)
    papers = run_search_from_state()
    saved_papers = supabase_service.upsert_project_papers(project["id"], papers)
    supabase_service.update_project_latest_outputs(
        project["id"],
        {
            "latest_papers": papers or [],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    workflow_state = load_workflow_state()

    return {
        "project": project,
        "search_queries": plan.get("queries", []),
        "papers": saved_papers or papers,
        "workflow_state": workflow_state,
    }


@app.get("/projects/{project_id}/repository")
def project_repository(project_id: str) -> dict:   # UUID → str
    _ensure_supabase()
    project = supabase_service.get_project(project_id)
    papers = supabase_service.list_project_papers(project_id)
    versions = supabase_service.list_versions(project_id)
    return {"project": project, "papers": papers, "versions": versions}


# ---------------------------------------------------------------------- #
# Project Members
# ---------------------------------------------------------------------- #

_ALLOWED_MEMBER_ROLES = {"viewer", "editor", "lead"}


@app.get("/projects/{project_id}/members")
def list_project_members(project_id: str) -> dict:    # UUID → str
    _ensure_supabase()
    members = supabase_service.list_project_members(project_id)
    return {"members": members}


def _require_project_owner(project_id: str, actor_user_id: Optional[str]) -> str:
    """Confirm the calling user is the project owner.

    `actor_user_id` comes from the request body (AddMemberRequest /
    UpdateMemberRoleRequest / CreateInvitationRequest). When it's
    missing or doesn't match the project's owner_id, raise 403.
    """
    if not actor_user_id or not str(actor_user_id).strip():
        raise HTTPException(
            status_code=403,
            detail="Only the project owner can perform this action.",
        )
    project = supabase_service.get_project(project_id)
    owner_id = project.get("owner_id") if isinstance(project, dict) else None
    if not owner_id or str(owner_id) != str(actor_user_id).strip():
        raise HTTPException(
            status_code=403,
            detail="Only the project owner can perform this action.",
        )
    return str(actor_user_id).strip()


@app.post("/projects/{project_id}/members")
def add_project_member(project_id: str, payload: AddMemberRequest) -> Dict:
    _ensure_supabase()
    _require_project_owner(project_id, payload.actor_user_id)
    role = (payload.role or "").strip().lower()
    if role not in _ALLOWED_MEMBER_ROLES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role '{payload.role}'. Expected one of "
                   f"{sorted(_ALLOWED_MEMBER_ROLES)}.",
        )
    user_id = (payload.user_id or "").strip()
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required.")
    try:
        member = supabase_service.add_project_member(project_id, user_id, role)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"member": member}


@app.patch("/projects/{project_id}/members/{member_id}")
def update_project_member_role(
    project_id: str,                              # UUID → str
    member_id: str,                                # UUID → str
    payload: UpdateMemberRoleRequest,
) -> Dict:
    _ensure_supabase()
    _require_project_owner(project_id, payload.actor_user_id)
    role = (payload.role or "").strip().lower()
    if role not in _ALLOWED_MEMBER_ROLES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role '{payload.role}'. Expected one of "
                   f"{sorted(_ALLOWED_MEMBER_ROLES)}.",
        )
    try:
        member = supabase_service.update_project_member_role(member_id, role)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if not member:
        raise HTTPException(status_code=404, detail="Member not found.")
    return {"member": member}


@app.delete("/projects/{project_id}/members/{member_id}")
def remove_project_member(
    project_id: str,                              # UUID → str
    member_id: str,                               # UUID → str
    payload: Optional[RevokeInvitationRequest] = None,   # owner-gated
) -> dict:
    _ensure_supabase()
    actor = (payload.actor_user_id if payload else None)
    _require_project_owner(project_id, actor)
    supabase_service.remove_project_member(member_id)
    return {"removed": True, "member_id": member_id}


@app.delete("/projects/{project_id}/members/by-user/{user_id}")
def leave_project(
    project_id: str,                              # UUID → str
    user_id: str,                                 # UUID → str of the leaver
    payload: LeaveProjectRequest,
) -> dict:
    """Allow a non-owner member to remove themselves from a project.

    Only the user identified by `user_id` (matched against the
    `actor_user_id` in the body) may call this; owners can use the
    generic DELETE endpoint above. The owner of a project cannot leave
    their own project through this route.
    """
    _ensure_supabase()
    if not payload.user_id or str(payload.user_id).strip() != str(user_id).strip():
        raise HTTPException(
            status_code=403,
            detail="You can only leave a project on your own behalf.",
        )
    project = supabase_service.get_project(project_id)
    owner_id = project.get("owner_id") if isinstance(project, dict) else None
    if owner_id and str(owner_id) == str(user_id).strip():
        raise HTTPException(
            status_code=400,
            detail="Project owners cannot leave their own project. "
                   "Delete the project instead.",
        )
    # Look up the membership row id and delete it.
    rows = supabase_service._request(  # noqa: SLF001 - intentional internal use
        "GET",
        "project_members",
        params={
            "project_id": f"eq.{project_id}",
            "user_id": f"eq.{user_id}",
            "select": "id",
        },
    )
    target_id = None
    if isinstance(rows, list) and rows:
        target_id = rows[0].get("id")
    if not target_id:
        raise HTTPException(
            status_code=404,
            detail="You are not a member of this project.",
        )
    supabase_service.remove_project_member(target_id)
    return {"removed": True, "member_id": target_id, "project_id": project_id}


# ---------------------------------------------------------------------- #
# Invitations (collaboration_requests)
# ---------------------------------------------------------------------- #


@app.get("/projects/{project_id}/invitations")
def list_project_invitations(
    project_id: str,                                  # UUID → str
    status: str | None = None,
) -> dict:
    _ensure_supabase()
    try:
        invitations = supabase_service.list_invitations(
            project_id=project_id, status=status
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"invitations": invitations}


@app.post("/projects/{project_id}/invitations")
def create_project_invitation(
    project_id: str,                                  # UUID → str
    payload: CreateInvitationRequest,
) -> dict:
    _ensure_supabase()
    _require_project_owner(project_id, payload.actor_user_id)
    role = (payload.role or "").strip().lower()
    if role not in _ALLOWED_MEMBER_ROLES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role '{payload.role}'. Expected one of "
                   f"{sorted(_ALLOWED_MEMBER_ROLES)}.",
        )
    try:
        invitation = supabase_service.create_invitation(
            project_id=project_id,
            email=payload.email,
            role=role,
            invited_by=payload.invited_by,
            message=payload.message,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"invitation": invitation}


@app.delete("/projects/{project_id}/invitations/{invitation_id}")
def revoke_project_invitation(
    project_id: str,                                  # UUID → str
    invitation_id: str,                               # UUID → str
    payload: Optional[RevokeInvitationRequest] = None,
) -> dict:
    _ensure_supabase()
    actor = (payload.actor_user_id if payload else None)
    _require_project_owner(project_id, actor)
    supabase_service.revoke_invitation(invitation_id)
    return {"revoked": True, "invitation_id": invitation_id}


@app.get("/invitations")
def list_my_invitations(email: str | None = None) -> dict:
    """Inbox for the invited user — matches by lowercased email."""
    _ensure_supabase()
    if not email:
        return {"invitations": []}
    invitations = supabase_service.list_invitations(email=email)
    pending = [inv for inv in invitations if (inv.get("status") or "").lower() == "pending"]
    return {"invitations": pending, "total": len(pending)}


@app.post("/invitations/{token}/accept")
def accept_invitation(token: str, payload: AcceptInvitationRequest) -> dict:
    _ensure_supabase()
    user_id = (payload.accepting_user_id or "").strip()
    if not user_id:
        raise HTTPException(status_code=400, detail="accepting_user_id is required.")
    try:
        invitation = supabase_service.accept_invitation(token, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"invitation": invitation}


@app.post("/invitations/{token}/decline")
def decline_invitation(token: str) -> dict:
    _ensure_supabase()
    try:
        invitation = supabase_service.decline_invitation(token)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"invitation": invitation}


@app.get("/projects")
def list_projects(owner_id: str | None = None) -> dict:
    _ensure_supabase()
    return {"projects": supabase_service.list_projects(owner_id=owner_id)}


@app.post("/projects/{project_id}/versions/save")
def save_version(project_id: str, payload: SaveVersionRequest) -> dict:    # UUID → str
    _ensure_supabase()
    project = supabase_service.get_project(project_id)
    selected_papers = supabase_service.list_project_papers(project_id, selected_only=True)
    latest_version = {
        "project_id": project_id,
        "created_by": project.get("owner_id"),
        "snapshot_name": payload.snapshot_name.strip(),
        "version_message": payload.version_message.strip() or None,
        "is_current": True,
        "summary": project.get("latest_summary") or {},
        "comparison": project.get("latest_comparison") or {},
        "research_gap": project.get("latest_research_gap") or {},
        "literature_review": project.get("latest_literature_review") or {},
        "papers": selected_papers or [],
    }
    if not latest_version["snapshot_name"]:
        raise HTTPException(status_code=400, detail="Version name is required.")
    supabase_service.update_project(project_id, {"current_version_id": None})
    saved = supabase_service.insert_version(latest_version)
    supabase_service.set_current_version(project_id, saved["id"])          # no int() cast
    supabase_service.update_project(project_id, {"current_version_id": saved["id"]})  # no int() cast
    return saved


@app.post("/projects/{project_id}/versions/restore")
def restore_version(project_id: str, payload: RestoreVersionRequest) -> dict:  # UUID → str
    _ensure_supabase()
    version = supabase_service.get_version(payload.version_id)
    if not version:
        raise HTTPException(status_code=404, detail="Version not found.")
    supabase_service.update_project_latest_outputs(
        project_id,
        {
            "latest_summary": version.get("summary") or {},
            "latest_comparison": version.get("comparison") or {},
            "latest_research_gap": version.get("research_gap") or {},
            "latest_literature_review": version.get("literature_review") or {},
            "latest_papers": version.get("papers") or [],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    selected_ids = [paper.get("id") for paper in (version.get("papers") or []) if paper.get("id")]  # no int() cast
    supabase_service.set_project_papers_selection(project_id, selected_ids)
    supabase_service.set_current_version(project_id, payload.version_id)
    supabase_service.update_project(project_id, {"current_version_id": payload.version_id})
    return {"restored": True, "version": version}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)