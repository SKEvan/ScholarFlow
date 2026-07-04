"""
state.py

Defines the shared state used throughout the LangGraph workflow.

Every agent receives the current state, updates the fields it is
responsible for, and returns the updated state.
"""

from typing import TypedDict, List, Dict, Optional


class LiteratureReviewState(TypedDict):
    """
    Shared state for the Literature Review Generation workflow.
    """

    # -------------------------
    # User Input
    # -------------------------

    topic: str

    # -------------------------
    # Query Planning Agent
    # -------------------------

    search_queries: List[str]

    # -------------------------
    # Search Agent
    # -------------------------

    papers: List[Dict]

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

    summaries: List[Dict]

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

    comparison: Optional[str]

    # -------------------------
    # Research Gap Agent
    # -------------------------

    research_gaps: Optional[str]

    # -------------------------
    # Literature Review Writer
    # -------------------------

    literature_review: Optional[str]

    # -------------------------
    # Validation Agent
    # -------------------------

    validation_report: Optional[str]

    validation_passed: bool

    # -------------------------
    # Workflow Metadata
    # -------------------------

    current_agent: str

    status: str

    errors: List[str]