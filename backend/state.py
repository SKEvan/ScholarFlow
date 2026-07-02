# ---------------------------------------------------------------------------
# Shared LangGraph state
# ---------------------------------------------------------------------------

from typing import List, TypedDict

from backend.agents.Querry_Planning_Agent import generate_search_queries


class LitReviewState(TypedDict, total=False):
    project_id: str
    topic: str
    search_queries: List[str]
    status: str
    errors: List[str]
    
    
# ---------------------------------------------------------------------------
# LangGraph node
# ---------------------------------------------------------------------------

def query_planning_agent(state: LitReviewState) -> LitReviewState:
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

    