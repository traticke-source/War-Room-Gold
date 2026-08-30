# Architecture

## MVP application flow

1. The user creates a decision brief and assigns priority weights totaling 100%.
2. Independent agent workers return validated public summaries: recommendation, confidence, score, arguments, risks, assumptions, unknowns, conditions, and questions.
3. A disagreement pass identifies material conflicts, followed by a capped debate (two rounds; a third only when unresolved conflict remains).
4. The Chairman receives summaries rather than private chain-of-thought and creates a verdict.

## Production data model

Use UUID primary keys and timestamps for `users`, `decisions`, `analysis_sessions`, `agents`, `agent_analyses`, `debates`, `debate_messages`, `final_reports`, `decision_outcomes`, `decision_weights`, and `agent_performance`.

Enable Row Level Security on every user-owned table. Policies should resolve ownership through the parent decision and `auth.uid()`; client-submitted user IDs must never be trusted.

## Reliability

Each agent call is independent and runs in parallel. Validate structured JSON at the server boundary; retry malformed transient responses once, mark failures explicitly, and continue the synthesis with available evidence where safe. API keys and system prompts remain server-only.
