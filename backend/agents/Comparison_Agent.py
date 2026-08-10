"""Agent 4: Comparison Agent.
Generates thematic comparison groups from paper summaries using Gemini.
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
from agent_utils import extract_json, iter_gemini_text, normalize_abstracts
from System_Prompts import COMPARISON_PROMPT

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
	raise EnvironmentError("GEMINI_API_KEY not found. Add it to backend/agents/.env.")

MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")
MAX_COMPARISON_RETRIES = 3
client = genai.Client(api_key=GEMINI_API_KEY)


def _build_prompt(
    abstracts: List[Dict[str, str]],
    desired_output_type: str,
    user_prompt: str = "",
) -> str:
	return COMPARISON_PROMPT.format(
		abstracts_json=json.dumps(abstracts, ensure_ascii=False, indent=2),
		output_type=desired_output_type,
		user_prompt=user_prompt or "No additional prompt provided.",
	)


def _run_comparison_from_abstracts(
	abstracts: List[Dict[str, str]],
	desired_output_type: str,
	persist: bool,
	user_prompt: str = "",
) -> Dict[str, Any]:
	if not abstracts:
		raise ValueError("No abstracts found. Provide paper abstracts first.")

	output_type = (desired_output_type or "Overall Comparison").strip() or "Overall Comparison"
	prompt = _build_prompt(abstracts, output_type, user_prompt)

	data: Dict[str, Any] = {}
	last_error: Optional[Exception] = None
	for attempt in range(1, MAX_COMPARISON_RETRIES + 1):
		try:
			response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
			data = extract_json(response.text or "")
			if data.get("content") is not None:
				break
			last_error = ValueError("Gemini returned empty or invalid comparison JSON.")
		except Exception as exc:
			last_error = exc

		if attempt < MAX_COMPARISON_RETRIES:
			time.sleep(1.5 * attempt)

	if not data:
		raise RuntimeError(last_error or "Gemini comparison failed.")

	comparison = data
	comparison["tool"] = comparison.get("tool") or "comparison"
	comparison["output_type"] = output_type
	comparison.setdefault("title", "Comparison")
	if persist:
		# JSON state update: persist the direct comparison response to workflow.json.
		update_workflow_state(
			{
				"abstracts": abstracts,
				"desired_output_type": desired_output_type,
				"comparison": comparison,
				"current_agent": "comparison",
				"status": "comparison_complete",
			}
		)
	return comparison


def run_comparison_from_payload(
	abstracts: List[Dict[str, str]],
	desired_output_type: str = "Overall Comparison",
	persist: bool = True,
	user_prompt: str = "",
) -> Dict[str, Any]:
	return _run_comparison_from_abstracts(abstracts, desired_output_type, persist, user_prompt)


def stream_comparison_from_abstracts(
	abstracts: List[Dict[str, str]],
	desired_output_type: str,
	user_prompt: str = "",
) -> "tuple[Iterator[str], Any]":
	"""Mirror of :func:`run_comparison_from_payload` that streams tokens."""
	if not abstracts:
		raise ValueError("No abstracts found. Provide paper abstracts first.")

	output_type = (desired_output_type or "Overall Comparison").strip() or "Overall Comparison"
	prompt = _build_prompt(abstracts, output_type, user_prompt)

	buffer: list[str] = []

	def _tokens() -> Iterator[str]:
		for chunk in iter_gemini_text(client, MODEL_NAME, prompt):
			buffer.append(chunk)
			yield chunk

	def _finalize() -> Dict[str, Any]:
		joined = "".join(buffer)
		data = extract_json(joined) if joined.strip() else {}
		if not data:
			raise RuntimeError("Gemini comparison stream produced no usable JSON.")
		data["tool"] = data.get("tool") or "comparison"
		data["output_type"] = output_type
		data.setdefault("title", "Comparison")
		return data

	return _tokens(), _finalize


def run_comparison_from_state() -> Dict[str, Any]:
	state = load_workflow_state()
	abstracts = normalize_abstracts(state.get("abstracts") or state.get("papers") or [])
	desired_output_type = state.get("desired_output_type") or "Overall Comparison"
	user_prompt = state.get("user_prompt") or ""
	return _run_comparison_from_abstracts(abstracts, desired_output_type, persist=True, user_prompt=user_prompt)


if __name__ == "__main__":
	try:
		result = run_comparison_from_state()
		print(json.dumps(result, ensure_ascii=False, indent=2))
	except Exception as exc:
		print(f"\nError: {exc}")
