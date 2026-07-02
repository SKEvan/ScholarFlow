"""
Agent 2 — Query Planning Agent
================================
Purpose:
    Convert the user's research topic into optimized academic search queries.
"""

from __future__ import annotations

import os
import re
from typing import List, Optional, TypedDict

from dotenv import load_dotenv
from google import genai

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY :
    raise EnvironmentError(
        "GEMINI_API_KEY not found. Add it to a .env file, e.g.\n"
        "GEMINI_API_KEY=your_key_here"
    )

client = genai.Client(api_key=GEMINI_API_KEY)
MODEL_NAME = os.getenv("MODEL_NAME", "gemini-2.5-flash")

# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------

PROMPT_TEMPLATE = """You are an academic research assistant.
Generate 5 to 10 distinct, high-quality academic search queries for the
following research topic. The queries should cover different angles,
subtopics, and relevant keywords a researcher would use on Google Scholar,
Semantic Scholar, or arXiv.

Research topic: "{topic}"

Return ONLY the queries, one per line, with no numbering, bullets, or
extra commentary.
"""


def _parse_queries(raw_text: str) -> List[str]:
    """Clean the LLM output into a deduplicated list of query strings."""
    lines = [line.strip() for line in raw_text.strip().splitlines()]
    queries: List[str] = []
    seen = set()

    for line in lines:
        cleaned = re.sub(r"^[\d\.\-\*\)\s]+", "", line).strip()
        if not cleaned:
            continue
        key = cleaned.lower()
        if key not in seen:
            seen.add(key)
            queries.append(cleaned)

    return queries


def generate_search_queries(topic: str, retries: int = 3) -> List[str]:
    """Call Gemini to turn a topic into a list of academic search queries."""
    if not topic or not topic.strip():
        raise ValueError("Topic must not be empty.")

    prompt = PROMPT_TEMPLATE.format(topic=topic.strip())
    last_error: Optional[Exception] = None

    for _attempt in range(1, retries + 1):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
            )
            text = response.text or ""
            queries = _parse_queries(text)
            if queries:
                return queries
            last_error = ValueError("LLM returned no parsable queries.")
        except Exception as e:
            last_error = e

    raise RuntimeError(
        f"Query Planning Agent failed after {retries} attempts: {last_error}"
    )


if __name__ == "__main__":
    topic = input("Enter research topic: ").strip()

    try:
        queries = generate_search_queries(topic)
        print("\nGenerated Queries:\n")
        for i, query in enumerate(queries, 1):
            print(f"{i}. {query}")
    except Exception as e:
        print(f"\nError: {e}")


