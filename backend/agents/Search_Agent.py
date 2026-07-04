"""
Agent 3 — Search Agent
========================
Purpose:
    Search academic papers for each query produced by the Query Planning
    Agent. Semantic Scholar is used as the PRIMARY source (broadest,
    richest metadata). arXiv and Crossref are used as SUPPLEMENTARY
    sources whenever Semantic Scholar alone does not return enough
    results for a query (per the guide: "only semantic API is not enough").

Input:  state["search_queries"] (List[str])
Output: state["papers"]         (List[dict])  -> each paper has:
        title, authors, abstract, year, doi, pdf_url, source

LLM: None (this agent does not call an LLM).

Install deps:
    pip install requests python-dotenv
"""

import os
import time
import json
from typing import TypedDict, List, Dict, Optional

import requests
from dotenv import load_dotenv
from workflow_state import load_workflow_state, update_workflow_state

load_dotenv()

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SEMANTIC_SCHOLAR_URL = "https://api.semanticscholar.org/graph/v1/paper/search"
SEMANTIC_SCHOLAR_API_KEY = os.getenv("SEMANTIC_SCHOLAR_API_KEY")  # optional, raises rate limits
ARXIV_URL = "http://export.arxiv.org/api/query"
CROSSREF_URL = "https://api.crossref.org/works"

MIN_RESULTS_PER_QUERY = 5   # if Semantic Scholar returns fewer than this, supplement
RESULTS_PER_QUERY = 10
REQUEST_TIMEOUT = 15        # seconds
MAX_RETRIES = 3



def _retry(fn, *args, **kwargs) -> Optional[requests.Response]:
    """Retry a request-returning function up to MAX_RETRIES times."""
    last_err = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = fn(*args, **kwargs)
            resp.raise_for_status()
            return resp
        except Exception as e:
            last_err = e
            time.sleep(1.5 * attempt)  # simple backoff
    print(f"[SearchAgent] Request failed after {MAX_RETRIES} retries: {last_err}")
    return None


def _normalize_title(title: str) -> str:
    return "".join(ch.lower() for ch in title if ch.isalnum())


def _extract_queries(raw_value) -> List[str]:
    """Return a clean list[str] from different possible state formats."""
    candidate = raw_value

    if isinstance(candidate, str):
        text = candidate.strip()
        if text:
            try:
                candidate = json.loads(text)
            except json.JSONDecodeError:
                candidate = [text]

    # Handle malformed stored output like ["```json", "{", ...]
    if isinstance(candidate, list) and any(str(item).strip().startswith("```") for item in candidate):
        joined = "\n".join(str(item) for item in candidate)
        joined = joined.replace("```json", "").replace("```", "").strip()
        try:
            parsed = json.loads(joined)
            if isinstance(parsed, dict):
                candidate = parsed.get("queries", [])
            elif isinstance(parsed, list):
                candidate = parsed
        except json.JSONDecodeError:
            pass

    if isinstance(candidate, dict):
        candidate = candidate.get("queries", [])

    if not isinstance(candidate, list):
        return []

    queries: List[str] = []
    seen = set()
    noise = {"{", "}", "[", "]", "```json", "```"}
    for item in candidate:
        cleaned = str(item).strip().strip('"').strip()
        if not cleaned or cleaned in noise:
            continue
        lowered = cleaned.lower()
        if lowered in seen:
            continue
        seen.add(lowered)
        queries.append(cleaned)
    return queries


# ---------------------------------------------------------------------------
# Provider 1 (PRIMARY): Semantic Scholar
# ---------------------------------------------------------------------------

def search_semantic_scholar(query: str, limit: int = RESULTS_PER_QUERY) -> List[Dict]:
    headers = {"x-api-key": SEMANTIC_SCHOLAR_API_KEY} if SEMANTIC_SCHOLAR_API_KEY else {}
    params = {
        "query": query,
        "limit": limit,
        "fields": "title,authors,abstract,year,externalIds,openAccessPdf",
    }
    resp = _retry(requests.get, SEMANTIC_SCHOLAR_URL, params=params, headers=headers, timeout=REQUEST_TIMEOUT)
    if not resp:
        return []

    papers = []
    for item in resp.json().get("data", []):
        papers.append({
            "title": item.get("title"),
            "authors": [a.get("name") for a in item.get("authors", [])],
            "abstract": item.get("abstract"),
            "year": item.get("year"),
            "doi": (item.get("externalIds") or {}).get("DOI"),
            "pdf_url": (item.get("openAccessPdf") or {}).get("url"),
            "source": "semantic_scholar",
        })
    return papers


# ---------------------------------------------------------------------------
# Provider 2 (SUPPLEMENTARY): arXiv
# ---------------------------------------------------------------------------

def search_arxiv(query: str, limit: int = RESULTS_PER_QUERY) -> List[Dict]:
    import xml.etree.ElementTree as ET

    params = {
        "search_query": f"all:{query}",
        "start": 0,
        "max_results": limit,
    }
    resp = _retry(requests.get, ARXIV_URL, params=params, timeout=REQUEST_TIMEOUT)
    if not resp:
        return []

    ns = {"atom": "http://www.w3.org/2005/Atom"}
    root = ET.fromstring(resp.text)

    papers = []
    for entry in root.findall("atom:entry", ns):
        title = entry.findtext("atom:title", default="", namespaces=ns).strip()
        summary = entry.findtext("atom:summary", default="", namespaces=ns).strip()
        published = entry.findtext("atom:published", default="", namespaces=ns)
        year = int(published[:4]) if published[:4].isdigit() else None
        authors = [a.findtext("atom:name", default="", namespaces=ns)
                   for a in entry.findall("atom:author", ns)]
        pdf_url = None
        for link in entry.findall("atom:link", ns):
            if link.attrib.get("title") == "pdf" or link.attrib.get("type") == "application/pdf":
                pdf_url = link.attrib.get("href")

        papers.append({
            "title": title,
            "authors": authors,
            "abstract": summary,
            "year": year,
            "doi": entry.findtext("{http://arxiv.org/schemas/atom}doi", default=None, namespaces=ns),
            "pdf_url": pdf_url,
            "source": "arxiv",
        })
    return papers


# ---------------------------------------------------------------------------
# Provider 3 (SUPPLEMENTARY): Crossref
# ---------------------------------------------------------------------------

def search_crossref(query: str, limit: int = RESULTS_PER_QUERY) -> List[Dict]:
    params = {"query": query, "rows": limit}
    resp = _retry(requests.get, CROSSREF_URL, params=params, timeout=REQUEST_TIMEOUT)
    if not resp:
        return []

    papers = []
    for item in resp.json().get("message", {}).get("items", []):
        title_list = item.get("title") or []
        authors = [
            f"{a.get('given', '')} {a.get('family', '')}".strip()
            for a in item.get("author", [])
        ] if item.get("author") else []
        year = None
        date_parts = item.get("published", {}).get("date-parts")
        if date_parts and date_parts[0]:
            year = date_parts[0][0]

        papers.append({
            "title": title_list[0] if title_list else None,
            "authors": authors,
            "abstract": item.get("abstract"),
            "year": year,
            "doi": item.get("DOI"),
            "pdf_url": item.get("link", [{}])[0].get("URL") if item.get("link") else None,
            "source": "crossref",
        })
    return papers


# ---------------------------------------------------------------------------
# Core orchestration: Semantic Scholar first, others only if needed
# ---------------------------------------------------------------------------

def search_papers_for_query(query: str) -> List[Dict]:
    results = search_semantic_scholar(query)

    # Semantic Scholar alone often isn't enough (rate limits, coverage gaps,
    # missing preprints/DOIs) -> supplement with arXiv and Crossref.
    if len(results) < MIN_RESULTS_PER_QUERY:
        results.extend(search_arxiv(query))
        results.extend(search_crossref(query))

    return results


def load_queries_from_state() -> List[str]:
    state = load_workflow_state()
    return _extract_queries(state.get("search_queries"))


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
    return unique


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

    for query in queries:
        try:
            all_papers.extend(search_papers_for_query(query))
        except Exception as e:
            errors.append(f"SearchAgent: query '{query}' failed: {e}")

    unique_papers = deduplicate_papers(all_papers)
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
