_: {
  "grill-me" = ''
    ---
    name: grill-me
    description: Relentlessly interview the user to stress-test a plan or design before implementation. Use when the user asks to be grilled, challenged, or questioned about an idea, plan, specification, or architecture.
    ---

    # Grill Me

    Interview the user about their plan or design until you reach a shared understanding. Surface hidden assumptions, unresolved dependencies, edge cases, and trade-offs before implementation begins.

    ## Protocol

    1. Inspect the available codebase, documentation, and conversation context before asking questions. Answer anything discoverable from those sources yourself.
    2. Build a decision tree from the plan. Follow one branch at a time and resolve prerequisite decisions before dependent ones.
    3. Ask exactly one question per turn, then wait for the user's answer.
    4. For every question, provide your recommended answer and a concise rationale. Make it easy for the user to accept the recommendation or supply a different decision.
    5. Challenge vague requirements, implicit assumptions, failure handling, boundaries, compatibility, security, performance, testing, rollout, and explicit non-goals when relevant.
    6. Keep track of settled decisions. Do not repeat resolved questions unless new information invalidates an earlier answer.
    7. Do not implement the plan during the interview unless the user explicitly ends the grilling and asks you to proceed.

    When the important branches are resolved, finish with a concise summary of the agreed decisions, remaining risks, and the next recommended action.
  '';
}
