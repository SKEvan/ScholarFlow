"""Activation entrypoint for the LangGraph literature review workflow."""

from __future__ import annotations

from dotenv import load_dotenv
from graph.nodes import router_agent
from graph.workflow import build_langgraph_workflow


load_dotenv(".env")

#from backend.agents.graph.workflow import run_langgraph_workflow_from_state


def main() -> None:
    print("Type a request to start or continue the workflow. Type 'exit' to quit.")
    while True:
        user_input = input("\nYour request: ").strip()
        if not user_input:
            print("No request provided. Please enter a request or type 'exit'.")
            continue
        if user_input.lower() in {"exit", "quit"}:
            print("Workflow session ended.")
            break

        state = router_agent(user_input)
        router_start_node = state["router_start_node"]
        router_end_node = state["router_end_node"]
        app = build_langgraph_workflow(router_start_node, router_end_node)
        result = app.invoke(state)


if __name__ == "__main__":
    main()
