"""Agent 5: Literature Review Agent.
Generates a concise literature review from the topic and comparison results using Gemini.
"""

from __future__ import annotations

import json
import os
import re
import time
from typing import Any, Dict, Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state
from System_Prompts import LITERATURE_REVIEW_PROMPT

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_LITERATURE_REVIEW_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)

def _format_payload(value) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2)


def _extract_json(text: str) -> Dict[str, Any]:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned)

    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start == -1 or end == -1 or end <= start:
            return {}
        try:
            data = json.loads(cleaned[start : end + 1])
        except json.JSONDecodeError:
            return {}

    return data if isinstance(data, dict) else {}


def run_literature_review_from_payload(
    topic: str,
    comparison: Dict[str, Any],
    summaries: list[Dict],
    persist: bool = True,
) -> Dict[str, Any]:
    topic = (topic or "").strip()
    if not topic:
        raise ValueError("No topic found. Run Querry_Planning_Agent.py first.")
    if not comparison:
        raise ValueError("No comparison found. Run Comparison_Agent.py first.")

    prompt = LITERATURE_REVIEW_PROMPT.format(
        topic=topic,
        comparison_json=_format_payload(comparison),
        summaries_json=_format_payload(summaries),
    )

    last_error: Optional[Exception] = None
    literature_review: Dict[str, Any] = {}
    for attempt in range(1, MAX_LITERATURE_REVIEW_RETRIES + 1):
        try:
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            literature_review = _extract_json(response.text or "")
            if literature_review:
                break
            last_error = ValueError("Gemini returned empty or invalid literature review JSON.")
        except Exception as exc:
            last_error = exc

        if attempt < MAX_LITERATURE_REVIEW_RETRIES:
            time.sleep(1.5 * attempt)

    if not literature_review:
        raise RuntimeError(last_error or "Gemini literature review failed.")

    if persist:
        # JSON state update: mirror the generated literature review into workflow.json.
        update_workflow_state(
            {
                "literature_review": literature_review,
                "current_agent": "literature_review",
                "status": "literature_review_complete",
            }
        )
    return literature_review


def run_literature_review_from_state() -> Dict[str, Any]:
    state = load_workflow_state()
    topic = (state.get("topic") or "").strip()
    comparison = state.get("comparison")
    summaries = state.get("summaries") or []

    if not topic:
        raise ValueError("No topic found in workflow.json. Run Querry_Planning_Agent.py first.")
    if not comparison:
        raise ValueError("No comparison found in workflow.json. Run Comparison_Agent.py first.")

    return run_literature_review_from_payload(topic, comparison, summaries, persist=True)


if __name__ == "__main__":
    try:
        review = run_literature_review_from_state()
        print(json.dumps(review, ensure_ascii=False, indent=2))
    except Exception as exc:
        print(f"\nError: {exc}")