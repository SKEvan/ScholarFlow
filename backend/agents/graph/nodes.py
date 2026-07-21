"""Shared LangGraph node functions for the literature review workflow."""

import sys
from pathlib import Path
from typing import Any, Dict, List, cast

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[3]
AGENTS_DIR = PROJECT_ROOT / "backend" / "agents"

for path in (PROJECT_ROOT, AGENTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

load_dotenv(AGENTS_DIR / ".env")

from backend.agents.Router_Agent import generate_route
from backend.agents.Comparison_Agent import run_comparison_from_summaries
from backend.agents.Literature_Review_Agent import run_literature_review_from_payload
from backend.agents.Querry_Planning_Agent import generate_search_plan
from backend.agents.Research_Gap_Agent import run_research_gap_from_payload
from backend.agents.Search_Agent import deduplicate_papers, search_papers_for_query
from backend.agents.Summary_Agent import run_summary_from_papers
from backend.agents.graph.state import (
    ComparisonState,
    LiteratureReviewState,
    LiteratureReviewStatePayload,
    Paper,
    Summary,
)
from backend.agents.workflow_state import update_workflow_state


def _sync_workflow_state(state: LiteratureReviewState) -> None:
    # JSON state update: mirror the current LangGraph state into workflow.json.
    update_workflow_state(
        {
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
    )


def _clear_workflow_artifacts(state: LiteratureReviewState) -> None:
    state["search_queries"] = []
    state["papers"] = []
    state["summaries"] = []
    state["comparison"] = cast(ComparisonState, {})
    state["research_gaps"] = cast(Any, {})
    state["literature_review"] = cast(LiteratureReviewStatePayload, {})
    state["validation_report"] = cast(Any, {})
    state["validation_passed"] = False
    state["errors"] = []
    
    

def router_agent(user_query: str) -> LiteratureReviewState:
    """LangGraph node: reads state['user_query'] , writes state['router_start_node'], state['router_end_node'], and state['router_reason']."""
    start_node, end_node, reason = generate_route(user_query)

    state = cast(LiteratureReviewState, {})

    state["user_query"] = user_query
    state["router_start_node"] = start_node
    state["router_end_node"] = end_node
    state["router_reason"] = reason
    state["current_agent"] = "router"
    state["status"] = "router_complete"

    return state

def query_planning_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['user_query'] and writes state['topic'] and state['search_queries']."""
    errors = list(state.get("errors", []))
    previous_topic = str(state.get("topic") or "").strip()
    user_query = str(state.get("user_query") or "").strip()
    # Keep state aligned to the latest request before planning runs.
    if user_query:
        state["topic"] = user_query

    if not previous_topic and not user_query:
        errors.append("QueryPlanningAgent: missing topic")
        state["errors"] = errors
        state["current_agent"] = "query_planning"
        state["status"] = "query_planning_failed"
        # LangGraph state update: keep the in-memory graph state consistent on failure.
        state["search_queries"] = []
        state["papers"] = []
        _sync_workflow_state(state)
        return state

    try:
        # Query planning owns topic extraction. If user_query is present, let the LLM infer topic from it.
        plan = generate_search_plan(user_query)
        queries = cast(List[str], plan.get("queries") or [])
        planned_topic = str(plan.get("topic") or "").strip()

        if planned_topic and previous_topic and planned_topic.lower() != previous_topic.lower():
            _clear_workflow_artifacts(state)
        elif planned_topic and not previous_topic:
            _clear_workflow_artifacts(state)

        # LangGraph state update: write generated queries into the in-memory state.
        state["search_queries"] = queries
        state["topic"] = planned_topic or previous_topic or user_query
        state["current_agent"] = "query_planning"
        state["status"] = "query_planning_complete"
    except Exception as e:
        errors.append(f"QueryPlanningAgent: {e}")
        state["errors"] = errors
        state["current_agent"] = "query_planning"
        # Fallback for quota/rate-limit failures: keep the workflow usable with fresh state.
        fallback_topic = user_query or previous_topic
        state["topic"] = fallback_topic
        state["search_queries"] = [fallback_topic] if fallback_topic else []
        state["papers"] = []
        state["status"] = "query_planning_complete" if state["search_queries"] else "query_planning_failed"

    _sync_workflow_state(state)
    return state


def search_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['search_queries'], writes state['papers']."""
    errors = list(state.get("errors", []))
    queries = state.get("search_queries") or []

    if not queries:
        errors.append("SearchAgent: no search_queries provided.")
        state["errors"] = errors
        state["current_agent"] = "search"
        state["status"] = "search_failed"
        # LangGraph state update: clear papers in memory when search cannot run.
        state["papers"] = []
        _sync_workflow_state(state)
        return state

    all_papers: List[Dict[str, Any]] = []
    for query in queries:
        try:
            all_papers.extend(search_papers_for_query(query))
        except Exception as e:
            errors.append(f"SearchAgent: query '{query}' failed: {e}")

    unique_papers = cast(List[Paper], deduplicate_papers(all_papers))

    # LangGraph state update: write deduplicated papers into the in-memory state.
    state["papers"] = unique_papers
    state["errors"] = errors
    state["current_agent"] = "search"
    state["status"] = "search_complete" if unique_papers else "search_failed"
    _sync_workflow_state(state)
    return state


def summary_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['papers'], writes state['summaries']."""
    errors = list(state.get("errors", []))
    papers = cast(List[Paper], state.get("papers") or [])

    if not papers:
        errors.append("SummaryAgent: no papers provided.")
        state["errors"] = errors
        state["current_agent"] = "summary"
        state["status"] = "summary_failed"
        # LangGraph state update: clear summaries in memory when summary cannot run.
        state["summaries"] = []
        _sync_workflow_state(state)
        return state

    try:
        # LangGraph state update: compute summaries in memory without touching workflow.json.
        summaries = cast(List[Summary], run_summary_from_papers(cast(List[Dict[str, Any]], papers), persist=False))
        state["summaries"] = summaries
        state["current_agent"] = "summary"
        state["status"] = "summary_complete"
    except Exception as e:
        errors.append(f"SummaryAgent: {e}")
        state["errors"] = errors
        state["current_agent"] = "summary"
        state["status"] = "summary_failed"

    _sync_workflow_state(state)
    return state


def comparison_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['summaries'], writes state['comparison']."""
    errors = list(state.get("errors", []))
    summaries = cast(List[Summary], state.get("summaries") or [])

    if not summaries:
        errors.append("ComparisonAgent: no summaries provided.")
        state["errors"] = errors
        state["current_agent"] = "comparison"
        state["status"] = "comparison_failed"
        # LangGraph state update: clear comparison in memory when comparison cannot run.
        state["comparison"] = cast(ComparisonState, {})
        _sync_workflow_state(state)
        return state

    try:
        # LangGraph state update: compute comparison in memory without touching workflow.json.
        comparison = cast(
            ComparisonState,
            run_comparison_from_summaries(cast(List[Dict[str, Any]], summaries), persist=False),
        )
        state["comparison"] = comparison
        state["current_agent"] = "comparison"
        state["status"] = "comparison_complete"
    except Exception as e:
        errors.append(f"ComparisonAgent: {e}")
        state["errors"] = errors
        state["current_agent"] = "comparison"
        state["status"] = "comparison_failed"

    _sync_workflow_state(state)
    return state


def research_gap_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['summaries'] and state['comparison'], writes state['research_gaps']."""
    errors = list(state.get("errors", []))
    summaries = cast(List[Summary], state.get("summaries") or [])
    comparison = state.get("comparison")

    if not summaries:
        errors.append("ResearchGapAgent: no summaries provided.")
        state["errors"] = errors
        state["current_agent"] = "research_gap"
        state["status"] = "research_gap_failed"
        # LangGraph state update: clear research gaps in memory when the node cannot run.
        state["research_gaps"] = cast(Any, {})
        _sync_workflow_state(state)
        return state

    if not comparison:
        errors.append("ResearchGapAgent: no comparison provided.")
        state["errors"] = errors
        state["current_agent"] = "research_gap"
        state["status"] = "research_gap_failed"
        # LangGraph state update: clear research gaps in memory when the node cannot run.
        state["research_gaps"] = cast(Any, {})
        _sync_workflow_state(state)
        return state

    try:
        # LangGraph state update: compute research gaps in memory without touching workflow.json.
        research_gaps = run_research_gap_from_payload(
            cast(List[Dict[str, Any]], summaries),
            cast(Dict[str, Any], comparison),
            persist=False,
        )
        state["research_gaps"] = research_gaps
        state["current_agent"] = "research_gap"
        state["status"] = "research_gap_complete"
    except Exception as e:
        errors.append(f"ResearchGapAgent: {e}")
        state["errors"] = errors
        state["current_agent"] = "research_gap"
        state["status"] = "research_gap_failed"

    _sync_workflow_state(state)
    return state


def literature_review_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['topic'] and state['comparison'], writes state['literature_review']."""
    errors = list(state.get("errors", []))
    topic = state.get("topic") or ""
    comparison = state.get("comparison")
    research_gaps = state.get("research_gaps")
    summaries = cast(List[Summary], state.get("summaries") or [])

    if not topic:
        errors.append("LiteratureReviewAgent: missing topic")
        state["errors"] = errors
        state["current_agent"] = "literature_review"
        state["status"] = "literature_review_failed"
        # LangGraph state update: clear literature_review in memory when the node cannot run.
        state["literature_review"] = cast(Any, {})
        _sync_workflow_state(state)
        return state

    if not comparison:
        errors.append("LiteratureReviewAgent: no comparison provided.")
        state["errors"] = errors
        state["current_agent"] = "literature_review"
        state["status"] = "literature_review_failed"
        # LangGraph state update: clear literature_review in memory when the node cannot run.
        state["literature_review"] = cast(Any, {})
        _sync_workflow_state(state)
        return state

    try:
        # LangGraph state update: compute the literature review in memory without touching workflow.json.
        literature_review = cast(
            LiteratureReviewStatePayload,
            run_literature_review_from_payload(
                topic,
                cast(Dict[str, Any], comparison),
                cast(Dict[str, Any] | None, research_gaps),
                cast(List[Dict[str, Any]], summaries),
                persist=False,
            ),
        )
        state["literature_review"] = literature_review
        state["current_agent"] = "literature_review"
        state["status"] = "literature_review_complete"
    except Exception as e:
        errors.append(f"LiteratureReviewAgent: {e}")
        state["errors"] = errors
        state["current_agent"] = "literature_review"
        state["status"] = "literature_review_failed"

    _sync_workflow_state(state)
    return state



    