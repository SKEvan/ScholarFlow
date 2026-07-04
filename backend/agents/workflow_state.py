"""Lightweight JSON-backed workflow state for standalone agent runs."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List


AGENTS_DIR = Path(__file__).resolve().parent
STATE_FILE = AGENTS_DIR / "workflow.json"


def _normalize_search_queries(value: Any) -> List[str]:
    if not isinstance(value, list):
        return []

    queries: List[str] = []
    seen = set()
    for item in value:
        cleaned = str(item).strip()
        if not cleaned:
            continue
        key = cleaned.lower()
        if key in seen:
            continue
        seen.add(key)
        queries.append(cleaned)
    return queries


def _default_state() -> Dict[str, Any]:
    return {
        "topic": "",
        "search_queries": [],
        "papers": [],
        "summaries": [],
        "comparison": None,
        "research_gaps": None,
        "literature_review": None,
        "validation_report": None,
        "validation_passed": False,
        "current_agent": "",
        "status": "",
        "errors": [],
    }


def load_workflow_state() -> Dict[str, Any]:
    state_file = STATE_FILE
    if not state_file.exists():
        return _default_state()

    try:
        with state_file.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except (OSError, json.JSONDecodeError):
        return _default_state()

    state = _default_state()
    if isinstance(data, dict):
        state.update(data)
    state["search_queries"] = _normalize_search_queries(state.get("search_queries"))
    return state


def save_workflow_state(state: Dict[str, Any]) -> None:
    state_file = STATE_FILE
    state_file.parent.mkdir(parents=True, exist_ok=True)
    normalized_state = dict(state)
    normalized_state["search_queries"] = _normalize_search_queries(
        normalized_state.get("search_queries")
    )

    with state_file.open("w", encoding="utf-8") as file:
        json.dump(normalized_state, file, indent=2)


def update_workflow_state(updates: Dict[str, Any]) -> Dict[str, Any]:
    state = load_workflow_state()
    state.update(updates)
    save_workflow_state(state)
    return state