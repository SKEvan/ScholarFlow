from datetime import datetime, timezone
import logging
from pathlib import Path
import sys

from fastapi import BackgroundTasks
from fastapi import FastAPI
from fastapi import HTTPException
from dotenv import load_dotenv
from pydantic import BaseModel, Field

BASE_DIR = Path(__file__).resolve().parent
AGENTS_DIR = BASE_DIR / "agents"
for path in (BASE_DIR, AGENTS_DIR):
    path_text = str(path)
    if path_text not in sys.path:
        sys.path.insert(0, path_text)

from supabase_service import SupabaseError
from supabase_service import supabase_service

load_dotenv(BASE_DIR / ".env")
load_dotenv(AGENTS_DIR / ".env")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="ScholarFlow Backend", version="0.1.0")


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


@app.post("/auth/complete-profile")
def complete_profile(payload: CompleteProfileRequest) -> dict:
    _ensure_supabase()
    profile = supabase_service.upsert_profile(
        payload.user_id,
        {
            "full_name": payload.full_name.strip() or None,
            "avatar_url": payload.avatar_url.strip() or None,
            "university": payload.university.strip() or None,
            "role": payload.role.strip() or None,
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


def _run_background_search(project_id: str, owner_id: str | None, queries: list[str]) -> None:
    """Background worker: runs the streaming search and incrementally persists results.

    Each per-query batch is pushed to Supabase. The frontend polls
    `/projects/{id}/search-status` to know when more papers have arrived.
    """
    from Search_Agent import run_search_streaming

    def _on_batch(batch_papers: list[dict], total_unique: list[dict]) -> None:
        # Persist the new batch (citations>0 already filtered by Search_Agent).
        if batch_papers:
            try:
                supabase_service.append_project_papers(project_id, batch_papers)
            except Exception as exc:
                logger.exception("append_project_papers failed for project %s", project_id)
        # Snapshot the running total so the next status poll can deliver quickly.
        try:
            supabase_service.update_project_latest_papers(project_id, total_unique)
            supabase_service.update_search_status(
                project_id,
                "in_progress",
                paper_count=len(total_unique),
            )
        except Exception:
            logger.exception("update_search_status failed for project %s", project_id)

    try:
        logger.info("[background-search] starting for project %s (%d queries)", project_id, len(queries))
        result = run_search_streaming(queries, _on_batch)
        final_papers = result.get("papers") or []
        errors = result.get("errors") or []
        terminal = "completed" if not errors else "partial"
        supabase_service.update_search_status(
            project_id,
            terminal,
            errors=errors,
            paper_count=len(final_papers),
        )
        supabase_service.update_project_latest_papers(project_id, final_papers)
        logger.info(
            "[background-search] project %s finished with %d papers, status=%s, errors=%d",
            project_id, len(final_papers), terminal, len(errors),
        )
    except Exception as exc:
        logger.exception("background search crashed for project %s", project_id)
        try:
            supabase_service.update_search_status(
                project_id,
                "failed",
                errors=[f"SearchAgent crashed: {exc}"],
            )
        except Exception:
            logger.exception("failed to mark search_status=failed for project %s", project_id)


@app.post("/projects/research")
def research_project(payload: ProjectResearchRequest, background_tasks: BackgroundTasks) -> dict:
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=400, detail="Project title is required.")

    _ensure_supabase()

    from Querry_Planning_Agent import generate_search_plan
    from workflow_state import update_workflow_state

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

    # Generate the search plan up front so the user knows which queries will run.
    try:
        plan = generate_search_plan(title)
        queries = list(plan.get("queries") or [])
    except Exception as exc:
        logger.exception("generate_search_plan failed for project %s", project["id"])
        queries = []
        plan = {"queries": []}

    update_workflow_state(
        {
            "topic": title,
            "user_query": title,
            "search_queries": queries,
            "desired_output_type": payload.desired_output_type or "",
            "current_agent": "project_research",
            "status": "project_research_started",
            "errors": [],
        }
    )

    # Mark the project as pending + record the plan so the UI can show them.
    supabase_service.update_project(
        project["id"],
        {
            "search_queries": queries,
            "search_status": "pending" if queries else "failed",
            "search_errors": [] if queries else ["Query Planning Agent returned no queries."],
            "latest_papers": [],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )

    # Schedule the streaming search. The HTTP response returns immediately so the
    # user can navigate to the project details screen while papers trickle in.
    if queries:
        background_tasks.add_task(
            _run_background_search,
            project["id"],
            payload.owner_id,
            queries,
        )

    return {
        "project": project,
        "search_queries": queries,
        "search_status": "pending" if queries else "failed",
        "papers": [],
    }


@app.get("/projects/{project_id}/search-status")
def project_search_status(project_id: str) -> dict:   # UUID → str
    _ensure_supabase()
    row = supabase_service.get_search_status(project_id)
    if not row:
        raise HTTPException(status_code=404, detail="Project not found.")
    return {
        "project_id": project_id,
        "search_status": row.get("search_status") or "pending",
        "search_errors": row.get("search_errors") or [],
        "paper_count": len(row.get("latest_papers") or []),
        "search_queries": row.get("search_queries") or [],
        "latest_papers": row.get("latest_papers") or [],
    }


@app.get("/projects/{project_id}/repository")
def project_repository(project_id: str) -> dict:   # UUID → str
    _ensure_supabase()
    project = supabase_service.get_project(project_id)
    papers = supabase_service.list_project_papers(project_id)
    versions = supabase_service.list_versions(project_id)
    return {
        "project": project,
        "papers": papers,
        "versions": versions,
        "search_status": project.get("search_status") or "pending",
        "search_errors": project.get("search_errors") or [],
    }


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