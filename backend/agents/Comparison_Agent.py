"""Agent 4: Comparison Agent.
Generates thematic comparison groups from paper summaries using Gemini.
"""

from __future__ import annotations

import json
import os
import re
import time
from typing import Dict, Optional

from dotenv import load_dotenv
from google import genai
from workflow_state import load_workflow_state, update_workflow_state
from System_Prompts import COMPARISON_PROMPT

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
	raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_COMPARISON_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


COMPARISON_PROMPT = COMPARISON_PROMPT


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


def run_comparison_from_summaries(summaries: list[Dict], persist: bool = True) -> Dict:
	if not summaries:
		raise ValueError("No summaries found. Run Summary_Agent.py first.")

	prompt = COMPARISON_PROMPT.format(
		summaries_json=json.dumps(summaries, ensure_ascii=False, indent=2)
	)

	data: Dict = {}
	last_error: Optional[Exception] = None
	for attempt in range(1, MAX_COMPARISON_RETRIES + 1):
		try:
			response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
			data = _extract_json(response.text or "")
			if isinstance(data.get("groups"), list):
				break
			last_error = ValueError("Gemini returned empty or invalid comparison JSON.")
		except Exception as exc:
			last_error = exc

		if attempt < MAX_COMPARISON_RETRIES:
			time.sleep(1.5 * attempt)

	if not isinstance(data.get("groups"), list):
		raise RuntimeError(last_error or "Gemini comparison failed.")

	comparison = {"groups": data.get("groups", [])}
	if persist:
		# JSON state update: persist the comparison payload to workflow.json.
		update_workflow_state(
			{
				"comparison": comparison,
				"current_agent": "comparison",
				"status": "comparison_complete",
			}
		)
	return comparison


def run_comparison_from_state() -> Dict:
	state = load_workflow_state()
	summaries = state.get("summaries") or []
	if not summaries:
		raise ValueError("No summaries found in workflow.json. Run Summary_Agent.py first.")
	return run_comparison_from_summaries(summaries, persist=True)


if __name__ == "__main__":
	try:
		result = run_comparison_from_state()
		print(f"Created {len(result.get('groups', []))} comparison group(s).")
	except Exception as exc:
		print(f"\nError: {exc}")
