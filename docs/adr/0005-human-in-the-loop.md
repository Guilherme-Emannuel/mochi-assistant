# ADR-0005: Human-in-the-loop approval for write actions

- **Status:** accepted
- **Date:** 2026-10-14

## Context
LLMs can misread requests ("move my Friday meeting" → the wrong meeting) and can be manipulated
by text they read (prompt injection in an event description or a message).

## Decision
Tools are split into **read** and **write**. A write tool never executes directly: it inserts a
row in `pending_actions` with a human-readable summary, and Mochi asks me to confirm.
The action runs only after an explicit "sim". Pending actions expire after 15 minutes.
Every decision and execution is written to `audit_log`.

## Consequences
- One extra confirmation step for writes, which is acceptable for a personal assistant.
- Mistakes are caught before they happen, and there's a full history of what Mochi did.
- Low-risk writes (e.g. `save_memory`) may skip approval, but they are still logged.
