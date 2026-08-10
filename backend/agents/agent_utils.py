from __future__ import annotations

import json
import re
from typing import Any, Dict, Iterable, Iterator, List


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


def iter_gemini_text(client: Any, model: str, prompt: str) -> Iterator[str]:
    """Yield text chunks from a Gemini streaming call.

    Falls back to a non-streaming single call if ``generate_content_stream`` is
    unavailable in the installed SDK version. The yielded strings concatenate
    to the same text that ``client.models.generate_content(...)`` returns.
    """
    stream_call = getattr(client.models, "generate_content_stream", None)
    if stream_call is None:
        # Older SDK: behave like the non-streaming caller (single chunk).
        response = client.models.generate_content(model=model, contents=prompt)
        text = getattr(response, "text", "") or ""
        if text:
            yield text
        return

    chunks = stream_call(model=model, contents=prompt)
    for chunk in chunks:
        # `chunk.text` may be empty for safety / role-only chunks.
        text = getattr(chunk, "text", None)
        if text:
            yield text