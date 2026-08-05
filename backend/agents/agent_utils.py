from __future__ import annotations

import json
import re
from typing import Any, Dict, List


def extract_json(text: str) -> Dict[str, Any]:
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


def normalize_abstracts(value: Any) -> List[Dict[str, str]]:
	if not isinstance(value, list):
		return []

	items: List[Dict[str, str]] = []
	for index, item in enumerate(value, start=1):
		title = ""
		abstract = ""

		if isinstance(item, dict):
			title = str(item.get("title") or item.get("paper_title") or "").strip()
			abstract = str(
				item.get("abstract")
				or item.get("text")
				or item.get("content")
				or item.get("body")
				or ""
			).strip()
		else:
			abstract = str(item).strip()

		if not abstract:
			continue

		items.append(
			{
				"title": title or f"Abstract {index}",
				"abstract": abstract,
			}
		)

	return items