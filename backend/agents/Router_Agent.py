"""Router agent for the literature review workflow."""

from __future__ import annotations

import json
import os
from typing import Any, Dict

from dotenv import load_dotenv
from google import genai
from backend.agents import workflow_state
from backend.agents.graph import state
from workflow_state import update_workflow_state



load_dotenv(".env")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
client = genai.Client(api_key=GEMINI_API_KEY)

from System_Prompts import ROUTER_PROMPT
from backend.agents.graph.state import LiteratureReviewState

def _parse_json_object(raw_text: str) -> Dict[str, Any]:
    text = raw_text.strip()
    if text.startswith("```"):
        text = text.removeprefix("```json").removeprefix("```").strip()
        if text.endswith("```"):
            text = text[:-3].strip()

    try:
        payload = json.loads(text)
        return payload if isinstance(payload, dict) else {}
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                payload = json.loads(text[start : end + 1])
                return payload if isinstance(payload, dict) else {}
            except json.JSONDecodeError:
                return {}
    return {}


def _normalize_route(value: Any, fallback: str) -> str:
    allowed = {
        "query_planning",
        "search",
        "summary",
        "comparison",
        "research_gap",
        "literature_review",
    }
    if not isinstance(value, str):
        return fallback
    cleaned = value.strip()
    return cleaned if cleaned in allowed else fallback


def _fallback_route_from_query(user_query: str) -> tuple[str, str, str]:
    lowered = (user_query or "").lower()
    if any(token in lowered for token in ["fetch", "find", "search", "papers", "articles", "studies"]):
        return "query_planning", "search", "fallback paper search request"
    if "summary" in lowered or "summar" in lowered or "shorter" in lowered:
        return "summary", "summary", "fallback summary request"
    if "comparison" in lowered:
        return "summary", "comparison", "fallback comparison request"
    if "research gap" in lowered or "gap" in lowered:
        return "summary", "research_gap", "fallback research gap request"
    return "query_planning", "literature_review", "fallback full workflow request"


def generate_route(user_query: str) -> tuple[str, str, str]:
    """Choose the workflow start and end nodes from the user's next request."""

    try:
        prompt = ROUTER_PROMPT.format(user_query=user_query)
        response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
        payload = _parse_json_object(response.text or "")

        start_node = payload.get("start_node")
        end_node = payload.get("end_node")
        reason = str(payload.get("reason") or "LLM router selection").strip()
        
        if start_node and end_node and start_node != end_node:
            update_workflow_state(
                    {
                        "router_start_node": start_node,
                        "router_end_node": end_node,
                        "router_reason": reason,
                        "current_agent": "router_agent",
                        "status": "routing_complete",
                        "errors": [],
                    }
                )
        
    except Exception as exc:
        start_node, end_node, fallback_reason = _fallback_route_from_query(user_query)
        reason = f"router fallback: {fallback_reason}; {exc}"

    return start_node, end_node, reason
