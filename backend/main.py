from datetime import datetime, timezone
from pathlib import Path
import sys

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

from supabase_service import supabase_service

load_dotenv(BASE_DIR / ".env")
load_dotenv(AGENTS_DIR / ".env")

app = FastAPI(title="ScholarFlow Backend", version="0.1.0")


class AbstractItem(BaseModel):
    title: str | None = None
    abstract: str


class AgentRequest(BaseModel):
    abstracts: list[AbstractItem] = Field(default_factory=list)
    desired_output_type: str = Field(default="")
    project_id: int | None = None
    selected_paper_ids: list[int] = Field(default_factory=list)
    user_prompt: str = Field(default="")


class ProjectResearchRequest(BaseModel):
    title: str
    description: str = Field(default="")
    status: str = Field(default="active")
    start_date: str | None = None
    deadline: str | None = None
    desired_output_type: str = Field(default="")
    owner_id: int | None = None
    collaborators: list[str] = Field(default_factory=list)


class SaveVersionRequest(BaseModel):
    snapshot_name: str
    version_message: str = Field(default="")


class RestoreVersionRequest(BaseModel):
    version_id: int


class SignUpRequest(BaseModel):
    email: str
    password: str
    full_name: str = Field(default="")
    university: str = Field(default="")
    role: str = Field(default="")
    research_interest: str = Field(default="")


class SignInRequest(BaseModel):
    email: str
    password: str


def _load_project_abstracts(project_id: int, selected_paper_ids: list[int] | None = None) -> list[dict]:
    selected_ids = selected_paper_ids or []
    papers = supabase_service.list_project_papers(project_id, selected_only=bool(selected_ids))
    if selected_ids:
        selected_set = {int(value) for value in selected_ids}
        papers = [paper for paper in papers if int(paper.get("id") or 0) in selected_set]
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

    _ensure_supabase()
    return supabase_service.sign_up_user(
        email=email,
        password=password,
        full_name=payload.full_name.strip(),
        university=payload.university.strip(),
        role=payload.role.strip(),
        research_interest=payload.research_interest.strip(),
    )


@app.post("/auth/signin")
def sign_in(payload: SignInRequest) -> dict:
    email = payload.email.strip()
    password = payload.password
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    if not password.strip():
        raise HTTPException(status_code=400, detail="Password is required.")

    _ensure_supabase()
    return supabase_service.sign_in_user(email=email, password=password)


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
        int(project["id"]),
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
    saved_papers = supabase_service.upsert_project_papers(int(project["id"]), papers)
    supabase_service.update_project_latest_outputs(
        int(project["id"]),
        {
            "latest_papers": papers,
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
def project_repository(project_id: int) -> dict:
    _ensure_supabase()
    project = supabase_service.get_project(project_id)
    papers = supabase_service.list_project_papers(project_id)
    versions = supabase_service.list_versions(project_id)
    return {"project": project, "papers": papers, "versions": versions}


@app.get("/projects")
def list_projects() -> dict:
    _ensure_supabase()
    return {"projects": supabase_service.list_projects()}


@app.post("/projects/{project_id}/versions/save")
def save_version(project_id: int, payload: SaveVersionRequest) -> dict:
    _ensure_supabase()
    project = supabase_service.get_project(project_id)
    selected_papers = supabase_service.list_project_papers(project_id, selected_only=True)
    latest_version = {
        "project_id": project_id,
        "created_by": project.get("owner_id"),
        "snapshot_name": payload.snapshot_name.strip(),
        "version_message": payload.version_message.strip() or None,
        "is_current": True,
        "summary": project.get("latest_summary"),
        "comparison": project.get("latest_comparison"),
        "research_gap": project.get("latest_research_gap"),
        "literature_review": project.get("latest_literature_review"),
        "papers": selected_papers,
    }
    if not latest_version["snapshot_name"]:
        raise HTTPException(status_code=400, detail="Version name is required.")
    supabase_service.update_project(project_id, {"current_version_id": None})
    saved = supabase_service.insert_version(latest_version)
    supabase_service.set_current_version(project_id, int(saved["id"]))
    supabase_service.update_project(project_id, {"current_version_id": int(saved["id"])})
    return saved


@app.post("/projects/{project_id}/versions/restore")
def restore_version(project_id: int, payload: RestoreVersionRequest) -> dict:
    _ensure_supabase()
    version = supabase_service.get_version(payload.version_id)
    if not version:
        raise HTTPException(status_code=404, detail="Version not found.")
    supabase_service.update_project_latest_outputs(
        project_id,
        {
            "latest_summary": version.get("summary"),
            "latest_comparison": version.get("comparison"),
            "latest_research_gap": version.get("research_gap"),
            "latest_literature_review": version.get("literature_review"),
            "latest_papers": version.get("papers"),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    selected_ids = [int(paper.get("id")) for paper in (version.get("papers") or []) if paper.get("id")]
    supabase_service.set_project_papers_selection(project_id, selected_ids)
    supabase_service.set_current_version(project_id, payload.version_id)
    supabase_service.update_project(project_id, {"current_version_id": payload.version_id})
    return {"restored": True, "version": version}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)