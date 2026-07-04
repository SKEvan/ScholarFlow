# ---------------------------------------------------------------------------
# Shared LangGraph state
# ---------------------------------------------------------------------------

from typing import Dict, Dict, List, TypedDict

from backend.agents.Querry_Planning_Agent import generate_search_queries
from backend.agents.Search_Agent import search_papers_for_query, deduplicate_papers
from backend.agents.graph.state import LiteratureReviewState

    


def query_planning_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['topic'], writes state['search_queries'].""" 
    errors = list(state.get("errors", []))
    topic = state.get("topic")

    if not topic:
        errors.append("QueryPlanningAgent: missing topic")
        state["errors"] = errors
        state["status"] = "query_planning_failed"
        return state

    try:
        queries = generate_search_queries(topic)
        state["search_queries"] = queries
        state["status"] = "query_planning_complete"
    except Exception as e:
        errors.append(f"QueryPlanningAgent: {e}")
        state["errors"] = errors
        state["status"] = "query_planning_failed"

    return state


def search_agent(state: LiteratureReviewState) -> LiteratureReviewState:
    """LangGraph node: reads state['search_queries'], writes state['papers']."""
    errors = state.get("errors", [])
    queries = state.get("search_queries") or []

    if not queries:
        errors.append("SearchAgent: no search_queries provided.")
        state["errors"] = errors
        state["status"] = "search_failed"
        state["papers"] = []
        return state

    all_papers: List[Dict] = []
    for query in queries:
        try:
            all_papers.extend(search_papers_for_query(query))
        except Exception as e:
            errors.append(f"SearchAgent: query '{query}' failed: {e}")

    unique_papers = deduplicate_papers(all_papers)

    state["papers"] = unique_papers
    state["errors"] = errors
    state["status"] = "search_complete" if unique_papers else "search_failed"
    return state



    