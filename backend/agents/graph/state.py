"""
state.py

Defines the shared state used throughout the LangGraph workflow.

Every agent receives the current state, updates the fields it is
responsible for, and returns the updated state.
"""

from typing import TypedDict, List, Dict, Any


class Paper(TypedDict, total=False):
    title: str
    authors: List[str]
    abstract: str
    year: int
    doi: str
    paper_url: str
    doi_url: str
    pdf_url: str
    citations: int
    source: str


class Summary(TypedDict, total=False):
    title: str
    authors: List[str]
    research_objective: str
    research_problem: str
    main_findings: str


class ComparisonGroup(TypedDict, total=False):
    theme: str
    papers: List[str]
    common_objectives: List[str]
    common_problems: List[str]
    common_findings: List[str]
    differences: List[str]
    unique_contributions: List[str]


class ComparisonState(TypedDict, total=False):
    groups: List[ComparisonGroup]


class LiteratureReviewSection(TypedDict, total=False):
    heading: str
    paragraph: str
    papers: List[str]


class LiteratureReviewStatePayload(TypedDict, total=False):
    title: str
    outline: List[str]
    sections: List[LiteratureReviewSection]


class LiteratureReviewState(TypedDict):
    """
    Shared state for the Literature Review Generation workflow.
    """

    # -------------------------
    # User Input
    # -------------------------

    topic: str
    user_query: str
    router_start_node: str
    router_end_node: str
    router_reason: str

    # -------------------------
    # Query Planning Agent
    # -------------------------

    search_queries: List[str]

    # -------------------------
    # Search Agent
    # -------------------------

    papers: List[Paper]

    # Example paper structure:
    #
    # {
    #     "title": "...",
    #     "authors": [...],
    #     "year": 2024,
    #     "abstract": "...",
    #     "doi": "...",
    #     "pdf_url": "...",
    # }

    # -------------------------
    # Summary Agent
    # -------------------------

    summaries: List[Summary]

    # Example summary:
    #
    # {
    #     "paper_title": "...",
    #     "objective": "...",
    #     "methodology": "...",
    #     "dataset": "...",
    #     "results": "...",
    #     "limitations": "..."
    # }

    # -------------------------
    # Comparison Agent
    # -------------------------

    comparison: ComparisonState

    # -------------------------
    # Research Gap Agent
    # -------------------------

    research_gaps: Dict[str, Any]

    # -------------------------
    # Literature Review Writer
    # -------------------------

    literature_review: LiteratureReviewStatePayload

    # -------------------------
    # Validation Agent
    # -------------------------

    validation_report: Dict[str, Any]

    validation_passed: bool

    # -------------------------
    # Workflow Metadata
    # -------------------------

    current_agent: str

    status: str

    errors: List[str]