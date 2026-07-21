"""LangGraph assembly for the literature review workflow."""

from __future__ import annotations

from pathlib import Path
from pdb import main
import sys
from typing import Any, Dict, cast

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[3]
AGENTS_DIR = PROJECT_ROOT / "backend" / "agents"

for path in (PROJECT_ROOT, AGENTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

load_dotenv(AGENTS_DIR / ".env")

from langgraph.graph import END, START, StateGraph

from backend.agents.Router_Agent import generate_route
from backend.agents.graph.nodes import (
    comparison_agent,
    literature_review_agent,
    query_planning_agent,
    research_gap_agent,
    router_agent,
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
        "user_query": state.get("user_query", ""),
        "router_start_node": state.get("router_start_node", ""),
        "router_end_node": state.get("router_end_node", ""),
        "router_reason": state.get("router_reason", ""),
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
        if "user_query" in initial_state:
            # New user request should start with a clean transient run context.
            seeded_state["errors"] = []
            seeded_state["status"] = ""
            seeded_state["current_agent"] = ""
            seeded_state["router_reason"] = ""

    return seeded_state


def build_langgraph_workflow(start_node: str, end_node: str ):
    """Construct a LangGraph workflow for a selected start and end segment."""
    graph = StateGraph(LiteratureReviewState)
    graph.add_node("query_planning", query_planning_agent)
    graph.add_node("search", search_agent)
    graph.add_node("summary", summary_agent)
    graph.add_node("comparison", comparison_agent)
    graph.add_node("research_gap", research_gap_agent)
    graph.add_node("literature_review", literature_review_agent)

    graph.add_edge(START, start_node)

    ordered_nodes = list(GRAPH_NODE_ORDER)
    start_index = ordered_nodes.index(start_node)
    end_index = ordered_nodes.index(end_node)

    if start_index <= end_index:
        for idx in range(start_index, end_index):
            graph.add_edge(ordered_nodes[idx], ordered_nodes[idx + 1])
        graph.add_edge(ordered_nodes[end_index], END)
    else:
        graph.add_edge(start_node, END)

    if start_node == end_node:
        graph.add_edge(start_node, END)

    return graph.compile()


def main() -> None:
    print("Enter your topic to start the workflow. Type 'exit' to quit.")
    user_input = input("\nYour topic: ").strip()
    if not user_input:
        print("No topic provided. Please enter a topic or type 'exit'.")
    if user_input.lower() in {"exit", "quit"}:
        print("Workflow session ended.")
        return

    state = cast(LiteratureReviewState, {})
    state["user_query"] = user_input
    app = build_langgraph_workflow("query_planning", "literature_review")
    result = app.invoke(state)    

if __name__ == "__main__":
    main()
