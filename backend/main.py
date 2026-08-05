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

load_dotenv(BASE_DIR / ".env")
load_dotenv(AGENTS_DIR / ".env")

app = FastAPI(title="ScholarFlow Backend", version="0.1.0")


class AbstractItem(BaseModel):
    title: str | None = None
    abstract: str


class AgentRequest(BaseModel):
    abstracts: list[AbstractItem] = Field(default_factory=list)
    desired_output_type: str = Field(default="")


class ProjectResearchRequest(BaseModel):
    title: str
    desired_output_type: str = Field(default="")


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


@app.post("/agents/summary")
def summary(payload: AgentRequest) -> dict:
    from Summary_Agent import run_summary_from_payload

    return run_summary_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "General Summary",
        persist=True,
    )


@app.post("/agents/comparison")
def comparison(payload: AgentRequest) -> dict:
    from Comparison_Agent import run_comparison_from_payload

    return run_comparison_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Overall Comparison",
        persist=True,
    )


@app.post("/agents/research-gap")
def research_gap(payload: AgentRequest) -> dict:
    from Research_Gap_Agent import run_research_gap_from_payload

    return run_research_gap_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Research Gaps",
        persist=True,
    )


@app.post("/agents/literature-review")
def literature_review(payload: AgentRequest) -> dict:
    from Literature_Review_Agent import run_literature_review_from_payload

    return run_literature_review_from_payload(
        [item.model_dump() for item in payload.abstracts],
        desired_output_type=payload.desired_output_type or "Narrative Review",
        persist=True,
    )


@app.post("/projects/research")
def research_project(payload: ProjectResearchRequest) -> dict:
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=400, detail="Project title is required.")

    from Querry_Planning_Agent import generate_search_plan
    from Search_Agent import run_search_from_state
    from workflow_state import update_workflow_state, load_workflow_state

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
    workflow_state = load_workflow_state()

    return {
        "project": {
            "title": title,
            "desired_output_type": payload.desired_output_type or "",
        },
        "search_queries": plan.get("queries", []),
        "papers": papers,
        "workflow_state": workflow_state,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)