"""Agent 5: Research Gap Agent.
Identifies research gaps from paper summaries and comparison themes using Gemini.
"""

from __future__ import annotations

import json
import os
import re
import time
from typing import Any, Dict, Optional

from dotenv import load_dotenv
from google import genai
from System_Prompts import RESEARCH_GAP_PROMPT
from workflow_state import load_workflow_state, update_workflow_state

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
	raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_RESEARCH_GAP_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


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


def run_research_gap_from_payload(
	summaries: list[Dict[str, Any]],
	comparison: Dict[str, Any],
	persist: bool = True,
) -> Dict[str, Any]:
	if not summaries:
		raise ValueError("No summaries found. Run Summary_Agent.py first.")
	if not comparison:
		raise ValueError("No comparison found. Run Comparison_Agent.py first.")

	prompt = RESEARCH_GAP_PROMPT.format(
		comparison_json=json.dumps(comparison, ensure_ascii=False, indent=2),
		summaries_json=json.dumps(summaries, ensure_ascii=False, indent=2),
	)

	data: Dict[str, Any] = {}
	last_error: Optional[Exception] = None
	for attempt in range(1, MAX_RESEARCH_GAP_RETRIES + 1):
		try:
			response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
			data = _extract_json(response.text or "")
			if isinstance(data.get("research_gaps"), list):
				break
			last_error = ValueError("Gemini returned empty or invalid research gap JSON.")
		except Exception as exc:
			last_error = exc

		if attempt < MAX_RESEARCH_GAP_RETRIES:
			time.sleep(1.5 * attempt)

	if not isinstance(data.get("research_gaps"), list):
		raise RuntimeError(last_error or "Gemini research gap generation failed.")

	research_gaps = {"research_gaps": data.get("research_gaps", [])}
	if persist:
		# JSON state update: persist the research gap payload to workflow.json.
		update_workflow_state(
			{
				"research_gaps": research_gaps,
				"current_agent": "research_gap",
				"status": "research_gap_complete",
			}
		)
	return research_gaps


def run_research_gap_from_state() -> Dict[str, Any]:
	state = load_workflow_state()
	summaries = state.get("summaries") or []
	comparison = state.get("comparison")
	if not summaries:
		raise ValueError("No summaries found in workflow.json. Run Summary_Agent.py first.")
	if not comparison:
		raise ValueError("No comparison found in workflow.json. Run Comparison_Agent.py first.")
	return run_research_gap_from_payload(summaries, comparison, persist=True)


if __name__ == "__main__":
	try:
		result = run_research_gap_from_state()
		print(f"Created {len(result.get('research_gaps', []))} research gap(s).")
	except Exception as exc:
		print(f"\nError: {exc}")