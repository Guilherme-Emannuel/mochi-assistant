# ADR-0002: Use the existing n8n as the agent orchestrator

- **Status:** accepted
- **Date:** 2026-10-14

## Context
Ready-made "desktop companion" projects (AILIS, Violet, Miko) bundle their own backend.
Running another full stack on a 6 GB server is costly, and most of them don't integrate
with Google Calendar or offer approval flows out of the box.
The server already runs n8n, PostgreSQL, Qdrant and a WhatsApp gateway (Evolution API).

## Decision
Build the brain as n8n workflows (AI Agent node + tools), with Postgres for structured data
and Qdrant for memory. The desktop mascot is a thin client that calls one webhook.

## Consequences
- No new long-running containers in the first milestones.
- Native nodes for Google Calendar, Postgres, schedules and webhooks.
- Workflows are versioned as JSON in `n8n/workflows/` and must be sanitized before committing.
- Logic split across nodes can get hard to test, so complex logic goes into small Code nodes or SQL functions.

## Alternatives considered
- **Violet / AILIS backend**: heavier, early-stage projects and less control over safety.
- **Custom Python agent (FastAPI + SDK)**: maximum control, but slower to deliver. It can replace n8n later behind the same webhook contract.
