"""Activation entrypoint for the LangGraph literature review workflow."""

from __future__ import annotations

from pathlib import Path
import sys

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[2]
AGENTS_DIR = PROJECT_ROOT / "backend" / "agents"

for path in (PROJECT_ROOT, AGENTS_DIR):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

load_dotenv(AGENTS_DIR / ".env")

from backend.agents.graph.workflow import run_langgraph_workflow_from_state


def main() -> None:
    topic = input("Enter research topic: ").strip()
    if not topic:
        print("No topic provided. Workflow cancelled.")
        return

    final_state = run_langgraph_workflow_from_state({"topic": topic})
    status = final_state.get("status", "")
    current_agent = final_state.get("current_agent", "")
    print(f"LangGraph workflow complete: {status} ({current_agent})")


if __name__ == "__main__":
    main()
