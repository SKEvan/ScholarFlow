"""Search papers for workflow queries and save results to workflow state."""

import os
import time
import json
from typing import List, Dict, Optional

import requests
from dotenv import load_dotenv
from workflow_state import load_workflow_state, update_workflow_state

load_dotenv()

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SEMANTIC_SCHOLAR_URL = "https://api.semanticscholar.org/graph/v1/paper/search"
SEMANTIC_SCHOLAR_API_KEY = os.getenv("SEMANTIC_SCHOLAR_API_KEY") or os.getenv("SEMANTIC_SEARCH_API_KEY")

RESULTS_PER_QUERY = 10
REQUEST_TIMEOUT = 15
MAX_RETRIES = 3
QUERY_INTERVAL_SECONDS = 2.0
QUERY_MAX_ATTEMPTS = 3
SEMANTIC_REQUEST_INTERVAL_SECONDS = 1.1
_last_semantic_request_ts = 0.0


def _throttle_semantic_scholar_requests() -> None:
    global _last_semantic_request_ts
    now = time.monotonic()
    elapsed = now - _last_semantic_request_ts
    if elapsed < SEMANTIC_REQUEST_INTERVAL_SECONDS:
        time.sleep(SEMANTIC_REQUEST_INTERVAL_SECONDS - elapsed)
    _last_semantic_request_ts = time.monotonic()



def _retry(fn, *args, **kwargs) -> Optional[requests.Response]:
    """Retry a request call up to MAX_RETRIES times."""
    last_err = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = fn(*args, **kwargs)
            resp.raise_for_status()
            return resp
        except Exception as e:
            last_err = e
            status_code = getattr(getattr(e, "response", None), "status_code", None)
            if status_code == 429:
                time.sleep(3 * attempt)
            else:
                time.sleep(1.5 * attempt)
    print(f"[SearchAgent] Request failed after {MAX_RETRIES} retries: {last_err}")
    return None


def _normalize_title(title: str) -> str:
    return "".join(ch.lower() for ch in title if ch.isalnum())


def _extract_queries(raw_value) -> List[str]:
    if isinstance(raw_value, dict):
        raw_value = raw_value.get("queries", [])

    if isinstance(raw_value, str):
        try:
            parsed = json.loads(raw_value)
            raw_value = parsed.get("queries", []) if isinstance(parsed, dict) else parsed
        except json.JSONDecodeError:
            raw_value = [raw_value]

    if not isinstance(raw_value, list):
        return []

    queries: List[str] = []
    seen = set()
    for item in raw_value:
        cleaned = str(item).strip()
        if not cleaned:
            continue
        key = cleaned.lower()
        if key in seen:
            continue
        seen.add(key)
        queries.append(cleaned)
    return queries


def search_semantic_scholar(query: str, limit: int = RESULTS_PER_QUERY) -> List[Dict]:
    if not SEMANTIC_SCHOLAR_API_KEY:
        raise ValueError(
            "Missing Semantic Scholar API key. Set SEMANTIC_SCHOLAR_API_KEY (or SEMANTIC_SEARCH_API_KEY) in your environment."
        )

    headers = {"x-api-key": SEMANTIC_SCHOLAR_API_KEY}
    params = {
        "query": query,
        "limit": limit,
        "fields": "title,authors,abstract,year,externalIds,openAccessPdf,citationCount,url",
    }
    _throttle_semantic_scholar_requests()
    resp = _retry(requests.get, SEMANTIC_SCHOLAR_URL, params=params, headers=headers, timeout=REQUEST_TIMEOUT)
    if not resp:
        return []

    papers = []
    for item in resp.json().get("data", []):
        external_ids = item.get("externalIds") or {}
        doi = external_ids.get("DOI")
        paper_url = item.get("url")
        doi_url = f"https://doi.org/{doi}" if doi else None
        pdf_url = (item.get("openAccessPdf") or {}).get("url")

        papers.append({
            "title": item.get("title"),
            "authors": [a.get("name") for a in item.get("authors", [])],
            "abstract": item.get("abstract"),
            "year": item.get("year"),
            "doi": doi,
            "paper_url": paper_url,
            "doi_url": doi_url,
            "pdf_url": pdf_url,
            "citations": item.get("citationCount", 0) or 0,
            "source": "semantic_scholar",
        })
    return papers

def search_papers_for_query(query: str) -> List[Dict]:
    return search_semantic_scholar(query)


def search_with_query_retries(query: str) -> List[Dict]:
    last_error = None
    for attempt in range(1, QUERY_MAX_ATTEMPTS + 1):
        try:
            papers = search_papers_for_query(query)
            if papers:
                return papers
            last_error = "empty response"
        except Exception as exc:
            last_error = str(exc)

        if attempt < QUERY_MAX_ATTEMPTS:
            time.sleep(QUERY_INTERVAL_SECONDS)

    raise RuntimeError(f"Semantic Scholar failed after {QUERY_MAX_ATTEMPTS} attempts ({last_error})")


def deduplicate_papers(papers: List[Dict]) -> List[Dict]:
    seen_doi, seen_title, unique = set(), set(), []
    for p in papers:
        if not p.get("title"):
            continue
        doi = (p.get("doi") or "").lower()
        title_key = _normalize_title(p["title"])
        if doi and doi in seen_doi:
            continue
        if title_key in seen_title:
            continue
        seen_doi.add(doi)
        seen_title.add(title_key)
        unique.append(p)
    return sorted(unique, key=lambda p: p.get("citations", 0), reverse=True)


def run_search_from_state() -> List[Dict]:
    state = load_workflow_state()
    queries = _extract_queries(state.get("search_queries"))
    print(f"[SearchAgent] Loaded search queries: {queries}")

    if not queries:
        raise ValueError(
            "No search queries found in workflow.json. Run Query_Planning_Agent.py first."
        )

    all_papers: List[Dict] = []
    errors = list(state.get("errors") or [])

    for idx, query in enumerate(queries):
        if idx > 0:
            time.sleep(QUERY_INTERVAL_SECONDS)
        try:
            all_papers.extend(search_with_query_retries(query))
        except Exception as e:
            errors.append(f"SearchAgent: query '{query}' failed: {e}")

    unique_papers = deduplicate_papers(all_papers)
    # JSON state update: persist the search results to workflow.json.
    update_workflow_state(
        {
            "search_queries": queries,
            "papers": unique_papers,
            "current_agent": "search",
            "status": "search_complete" if unique_papers else "search_failed",
            "errors": errors,
        }
    )
    return unique_papers


if __name__ == "__main__":
    try:
        papers = run_search_from_state()
        print(f"Found {len(papers)} unique papers.")
    except Exception as e:
        print(f"\nError: {e}")
