"""LangGraph assembly for the literature review workflow."""

from __future__ import annotations

from pathlib import Path
import sys
from typing import Any, Dict

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[3]
AGENTS_DIR = PROJECT_ROOT / "backend" / "agents"

for path in (PROJECT_ROOT, AGENTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

load_dotenv(AGENTS_DIR / ".env")

from langgraph.graph import END, START, StateGraph

from backend.agents.graph.nodes import (
    comparison_agent,
    literature_review_agent,
    query_planning_agent,
    research_gap_agent,
    search_agent,
    summary_agent,
)
from backend.agents.graph.state import LiteratureReviewState
from backend.agents.workflow_state import load_workflow_state


GRAPH_NODE_ORDER = (
    "query_planning",
    "search",
    "summary",
    "comparison",
    "research_gap",
    "literature_review",
)


def _seed_state(initial_state: Dict[str, Any] | None = None) -> Dict[str, Any]:
    state = load_workflow_state()
    seeded_state: Dict[str, Any] = {
        "topic": state.get("topic", ""),
        "search_queries": state.get("search_queries", []),
        "papers": state.get("papers", []),
        "summaries": state.get("summaries", []),
        "comparison": state.get("comparison"),
        "research_gaps": state.get("research_gaps"),
        "literature_review": state.get("literature_review"),
        "validation_report": state.get("validation_report"),
        "validation_passed": state.get("validation_passed", False),
        "current_agent": state.get("current_agent", ""),
        "status": state.get("status", ""),
        "errors": state.get("errors", []),
    }

    if initial_state:
        seeded_state.update(initial_state)

    return seeded_state


def build_langgraph_workflow():
    """Construct the linear LangGraph workflow requested by the user."""
    graph = StateGraph(LiteratureReviewState)
    graph.add_node("query_planning", query_planning_agent)
    graph.add_node("search", search_agent)
    graph.add_node("summary", summary_agent)
    graph.add_node("comparison", comparison_agent)
    graph.add_node("research_gap", research_gap_agent)
    graph.add_node("literature_review", literature_review_agent)

    graph.add_edge(START, "query_planning")
    graph.add_edge("query_planning", "search")
    graph.add_edge("search", "summary")
    graph.add_edge("summary", "comparison")
    graph.add_edge("comparison", "research_gap")
    graph.add_edge("research_gap", "literature_review")
    graph.add_edge("literature_review", END)

    return graph.compile()


def run_langgraph_workflow(initial_state: Dict[str, Any] | None = None) -> Dict[str, Any]:
    """Execute the compiled LangGraph workflow from the current workflow state."""
    app = build_langgraph_workflow()
    result = app.invoke(_seed_state(initial_state))
    return dict(result)


def run_langgraph_workflow_from_state(
    initial_state: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    return run_langgraph_workflow(initial_state)


if __name__ == "__main__":
    final_state = run_langgraph_workflow_from_state()
    print(final_state.get("status", ""))
