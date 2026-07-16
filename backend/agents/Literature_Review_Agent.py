"""Agent 5: Literature Review Agent.
Generates a concise literature review from the topic and comparison results using Gemini.
"""

from __future__ import annotations

import json
import os
import time
from typing import Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_LITERATURE_REVIEW_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


LITERATURE_REVIEW_PROMPT = """
You are an academic research assistant.

Write a concise literature review for the research topic below using the paper summaries and comparison themes.

Rules:
- Use only the provided topic, summaries, and comparison.
- Include a short numbered outline before the literature review.
- Keep the outline to exactly 4 short points.
- Make each outline point map to one of the major comparison themes.
- Then write the literature review in clear academic prose.
- Keep both sections short and focused.
- Mention the main themes, the shared direction of the literature, and the main gaps or tensions.
- Use simple text headings like "Outline" and "Literature Review".
- Number the outline points as 1., 2., 3., and 4.
- Do not add extra JSON.

Topic:
{topic}

Comparison JSON:
{comparison_json}

Summaries JSON:
{summaries_json}
"""


def _format_payload(value) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2)


def run_literature_review_from_state() -> str:
    state = load_workflow_state()
    topic = (state.get("topic") or "").strip()
    comparison = state.get("comparison")
    summaries = state.get("summaries") or []

    if not topic:
        raise ValueError("No topic found in workflow.json. Run Querry_Planning_Agent.py first.")
    if not comparison:
        raise ValueError("No comparison found in workflow.json. Run Comparison_Agent.py first.")

    prompt = LITERATURE_REVIEW_PROMPT.format(
        topic=topic,
        comparison_json=_format_payload(comparison),
        summaries_json=_format_payload(summaries),
    )

    last_error: Optional[Exception] = None
    literature_review = ""
    for attempt in range(1, MAX_LITERATURE_REVIEW_RETRIES + 1):
        try:
            response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
            literature_review = (response.text or "").strip()
            if literature_review:
                break
            last_error = ValueError("Gemini returned an empty literature review.")
        except Exception as exc:
            last_error = exc

        if attempt < MAX_LITERATURE_REVIEW_RETRIES:
            time.sleep(1.5 * attempt)

    if not literature_review:
        raise RuntimeError(last_error or "Gemini literature review failed.")

    update_workflow_state(
        {
            "literature_review": literature_review,
            "current_agent": "literature_review",
            "status": "literature_review_complete",
        }
    )
    return literature_review


if __name__ == "__main__":
    try:
        review = run_literature_review_from_state()
        print(review)
    except Exception as exc:
        print(f"\nError: {exc}")