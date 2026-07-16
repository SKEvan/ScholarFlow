"""
Agent 3: Summary Agent
This agent summarizes the top-cited papers from the search results using Gemini.
"""

from __future__ import annotations
from System_Prompts import SUMMARY_PROMPT

import json
import os
import re
from typing import Dict, List, Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state

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


def _extract_json(text: str) -> Dict:
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


def _normalize_authors(value) -> List[str]:
    if isinstance(value, list):
        return [str(author).strip() for author in value if str(author).strip()]
    if isinstance(value, str):
        cleaned = value.strip()
        return [cleaned] if cleaned else []
    return []


def _summarize_paper(paper: Dict) -> Dict:
    prompt = SUMMARY_PROMPT.format(
        title=paper.get("title", ""),
        authors=", ".join(paper.get("authors") or []),
        abstract=paper.get("abstract", ""),
    )

    data: Dict = {}
    last_error: Optional[Exception] = None
    for attempt in range(1, MAX_SUMMARY_RETRIES + 1):
        try:
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            data = _extract_json(response.text or "")
            if data:
                break
            last_error = ValueError("Gemini returned empty or unparsable JSON.")
        except Exception as exc:
            last_error = exc

        if attempt < MAX_SUMMARY_RETRIES:
            import time

            time.sleep(1.5 * attempt)

    if not data:
        raise RuntimeError(last_error or "Gemini summary failed.")

    return {
        "title": data.get("title") or paper.get("title", ""),
        "authors": _normalize_authors(data.get("authors") or paper.get("authors", [])),
        "research_objective": data.get("research_objective", "Not stated"),
        "research_problem": data.get("research_problem", "Not stated"),
        "main_findings": data.get("main_findings", "Not stated"),
    }


def run_summary_from_papers(papers: List[Dict], persist: bool = True) -> List[Dict]:
    top_papers = sorted(
        [paper for paper in papers if paper.get("title") and paper.get("abstract")],
        key=lambda paper: paper.get("citations", 0) or 0,
        reverse=True,
    )[:TOP_PAPERS]

    if not top_papers:
        raise ValueError("No papers with abstracts found.")

    summaries: List[Dict] = []
    errors: List[str] = []

    for paper in top_papers:
        try:
            summaries.append(_summarize_paper(paper))
        except Exception as exc:
            errors.append(f"SummaryAgent: paper '{paper.get('title', '')}' failed: {exc}")

    if persist:
        # JSON state update: mirror the generated summaries into workflow.json.
        update_workflow_state(
            {
                "summaries": summaries,
                "current_agent": "summary",
                "status": "summary_complete" if summaries else "summary_failed",
                "errors": errors,
            }
        )
    return summaries


def run_summary_from_state() -> List[Dict]:
    state = load_workflow_state()
    papers = state.get("papers") or []
    return run_summary_from_papers(papers, persist=True)


if __name__ == "__main__":
    try:
        summaries = run_summary_from_state()
        print(f"Generated {len(summaries)} summaries.")
    except Exception as exc:
        print(f"\nError: {exc}")