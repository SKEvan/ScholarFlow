"""
Agent 3: Summary Agent
This agent summarizes the top-cited papers from the search results using Gemini.
"""

from __future__ import annotations
from System_Prompts import SUMMARY_PROMPT

import json
import os
import time
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state
from agent_utils import extract_json, normalize_abstracts

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise EnvironmentError(
        "GEMINI_API_KEY not found. Add it to backend/agents/.env."
    )

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
TOP_PAPERS = int(os.getenv("TOP_SUMMARY_PAPERS", "5"))
MAX_SUMMARY_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


def _build_prompt(
    abstracts: List[Dict[str, str]],
    desired_output_type: str,
    user_prompt: str = "",
) -> str:
    return SUMMARY_PROMPT.format(
        abstracts_json=json.dumps(abstracts, ensure_ascii=False, indent=2),
        output_type=desired_output_type,
        user_prompt=user_prompt or "No additional prompt provided.",
    )


def _run_summary_from_abstracts(
    abstracts: List[Dict[str, str]],
    desired_output_type: str,
    user_prompt: str = "",
) -> Dict[str, Any]:
    if not abstracts:
        raise ValueError("No abstracts found. Provide paper abstracts first.")

    output_type = (desired_output_type or "General Summary").strip() or "General Summary"
    prompt = _build_prompt(abstracts, output_type, user_prompt)

    data: Dict[str, Any] = {}
    last_error: Optional[Exception] = None
    for attempt in range(1, MAX_SUMMARY_RETRIES + 1):
        try:
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            data = extract_json(response.text or "")
            if data.get("content") is not None:
                break
            last_error = ValueError("Gemini returned empty or invalid summary JSON.")
        except Exception as exc:
            last_error = exc

        if attempt < MAX_SUMMARY_RETRIES:
            import time

            time.sleep(1.5 * attempt)

    if not data:
        raise RuntimeError(last_error or "Gemini summary generation failed.")

    data["tool"] = data.get("tool") or "summary"
    data["output_type"] = output_type
    data.setdefault("title", "Summary")
    return data


def run_summary_from_payload(
    abstracts: List[Dict[str, str]],
    desired_output_type: str = "General Summary",
    persist: bool = True,
    user_prompt: str = "",
) -> Dict[str, Any]:
    result = _run_summary_from_abstracts(abstracts, desired_output_type, user_prompt)

    if persist:
        # JSON state update: persist the direct summary response to workflow.json.
        update_workflow_state(
            {
                "abstracts": abstracts,
                "desired_output_type": desired_output_type,
                "user_prompt": user_prompt,
                "summary": result,
                "current_agent": "summary",
                "status": "summary_complete",
            }
        )
    return result


def run_summary_from_papers(papers: List[Dict], persist: bool = True) -> Dict[str, Any]:
    abstracts = normalize_abstracts(papers)
    return run_summary_from_payload(abstracts, persist=persist)


def run_summary_from_state() -> Dict[str, Any]:
    state = load_workflow_state()
    abstracts = normalize_abstracts(state.get("abstracts") or state.get("papers") or [])
    desired_output_type = state.get("desired_output_type") or "General Summary"
    user_prompt = state.get("user_prompt") or ""
    return run_summary_from_payload(abstracts, desired_output_type, persist=True, user_prompt=user_prompt)


if __name__ == "__main__":
    try:
        summary = run_summary_from_state()
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    except Exception as exc:
        print(f"\nError: {exc}")