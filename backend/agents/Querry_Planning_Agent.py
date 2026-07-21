"""
Agent 1 — Query Planning Agent
================================
Purpose:
    Convert the user's research topic into optimized academic search queries.
"""

from __future__ import annotations

import os
import re
import json
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from google import genai
from System_Prompts import QUERY_GENERATOR_PROMPT
from workflow_state import update_workflow_state

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY :
    raise EnvironmentError(
        "GEMINI_API_KEY not found. Add it to a .env file, e.g.\n"
        "GEMINI_API_KEY=your_key_here"
    )

client = genai.Client(api_key=GEMINI_API_KEY)
MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")

# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------



def _parse_query_payload(raw_text: str) -> tuple[str, List[str]]:
    """Extract topic and deduplicated queries from JSON model output."""

    text = raw_text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)

    raw_topic = ""
    raw_queries: List[str] = []

    # Try full JSON object first.
    try:
        payload = json.loads(text)
        if isinstance(payload, dict):
            maybe_topic = payload.get("topic", "")
            if isinstance(maybe_topic, str):
                raw_topic = maybe_topic.strip()
            maybe_queries = payload.get("queries", [])
            if isinstance(maybe_queries, list):
                raw_queries = maybe_queries
        elif isinstance(payload, list):
            raw_queries = payload
    except json.JSONDecodeError:
        # Fallback: extract first JSON object embedded in text.
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                payload = json.loads(text[start : end + 1])
                if isinstance(payload, dict):
                    maybe_topic = payload.get("topic", "")
                    if isinstance(maybe_topic, str):
                        raw_topic = maybe_topic.strip()
                maybe_queries = payload.get("queries", []) if isinstance(payload, dict) else []
                if isinstance(maybe_queries, list):
                    raw_queries = maybe_queries
            except json.JSONDecodeError:
                raw_queries = []

    queries: List[str] = []
    seen = set()
    for query in raw_queries:
        cleaned = str(query).strip()
        if not cleaned:
            continue
        key = cleaned.lower()
        if key in seen:
            continue
        seen.add(key)
        queries.append(cleaned)

    return raw_topic, queries


def generate_search_plan(user_query: str | None = None, retries: int = 3) -> Dict[str, Any]:
    """Call Gemini to produce a normalized topic and academic search queries."""
    prompt = QUERY_GENERATOR_PROMPT.format(
        user_query=(user_query or "").strip(),
    )
    last_error: Optional[Exception] = None

    for _ in range(1, retries + 1):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
            )
            text = response.text or ""
            parsed_topic, queries = _parse_query_payload(text)
            if queries:
                final_topic = parsed_topic or topic.strip() or (user_query or "").strip()
                # JSON state update: persist the generated topic and queries to workflow.json.
                update_workflow_state(
                    {
                        "topic": final_topic,
                        "search_queries": queries,
                        "current_agent": "query_planning",
                        "status": "query_planning_complete",
                        "errors": [],
                    }
                )
                return {"topic": final_topic, "queries": queries}
            last_error = ValueError("LLM returned no parsable queries.")
        except Exception as e:
            last_error = e

    raise RuntimeError(
        f"Query Planning Agent failed after {retries} attempts: {last_error}"
    )


def generate_search_queries(user_query: str | None = None, retries: int = 3) -> List[str]:
    """Backward-compatible wrapper that returns only the query list."""
    plan = generate_search_plan(user_query, retries=retries)
    return list(plan.get("queries") or [])


if __name__ == "__main__":
    topic = input("Enter research topic: ").strip()

    try:
        queries = generate_search_queries(topic)
        print("\nGenerated Queries:\n")
        for i, query in enumerate(queries, 1):
            print(f"{i}. {query}")
    except Exception as e:
        print(f"\nError: {e}")


