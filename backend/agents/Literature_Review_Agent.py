"""Agent 5: Literature Review Agent.
Generates a concise literature review from the topic and comparison results using Gemini.
"""

from __future__ import annotations

import json
import os
import re
import time
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state
from System_Prompts import LITERATURE_REVIEW_PROMPT
from agent_utils import extract_json, normalize_abstracts

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_LITERATURE_REVIEW_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


def _build_prompt(abstracts: List[Dict[str, str]], desired_output_type: str) -> str:
    return LITERATURE_REVIEW_PROMPT.format(
        abstracts_json=json.dumps(abstracts, ensure_ascii=False, indent=2),
        output_type=desired_output_type,
    )


def _run_literature_review_from_abstracts(
    abstracts: List[Dict[str, str]],
    desired_output_type: str,
) -> Dict[str, Any]:
    if not abstracts:
        raise ValueError("No abstracts found. Provide paper abstracts first.")

    output_type = (desired_output_type or "Narrative Review").strip() or "Narrative Review"
    prompt = _build_prompt(abstracts, output_type)

    last_error: Optional[Exception] = None
    literature_review: Dict[str, Any] = {}
    for attempt in range(1, MAX_LITERATURE_REVIEW_RETRIES + 1):
        try:
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            literature_review = extract_json(response.text or "")
            if literature_review.get("content") is not None:
                break
            last_error = ValueError("Gemini returned empty or invalid literature review JSON.")
        except Exception as exc:
            last_error = exc

        if attempt < MAX_LITERATURE_REVIEW_RETRIES:
            time.sleep(1.5 * attempt)

    if not literature_review:
        raise RuntimeError(last_error or "Gemini literature review failed.")

    literature_review["tool"] = literature_review.get("tool") or "literature_review"
    literature_review["output_type"] = output_type
    literature_review.setdefault("title", "Literature Review")

    return literature_review


def run_literature_review_from_payload(
    abstracts: List[Dict[str, str]],
    desired_output_type: str = "Narrative Review",
    persist: bool = True,
) -> Dict[str, Any]:
    literature_review = _run_literature_review_from_abstracts(abstracts, desired_output_type)

    if persist:
        # JSON state update: persist the direct literature review response to workflow.json.
        update_workflow_state(
            {
                "abstracts": abstracts,
                "desired_output_type": desired_output_type,
                "literature_review": literature_review,
                "current_agent": "literature_review",
                "status": "literature_review_complete",
            }
        )
    return literature_review


def run_literature_review_from_state() -> Dict[str, Any]:
    state = load_workflow_state()
    abstracts = normalize_abstracts(state.get("abstracts") or state.get("papers") or [])
    desired_output_type = state.get("desired_output_type") or "Narrative Review"
    return run_literature_review_from_payload(abstracts, desired_output_type, persist=True)


if __name__ == "__main__":
    try:
        review = run_literature_review_from_state()
        print(json.dumps(review, ensure_ascii=False, indent=2))
    except Exception as exc:
        print(f"\nError: {exc}")