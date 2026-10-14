# Day 01 — Assessing the server and choosing the architecture

**Date:** 2026-10-14 · **Milestone:** M0

## What I did
- Defined the goal: a personal AI secretary with a 3D desktop mascot, usable from my phone, safe by default.
- Compared ready-made desktop companions (AILIS, Violet, Miko).
- Ran a **read-only** assessment of my home server (`scripts/diagnose-server.sh`).

## What I found
- The CPU (i7-860, 2009) has no AVX, the GPU is a GeForce 9500 GT, and there is ~3.5 GB of free RAM.
  **Running an LLM locally isn't realistic** → [ADR-0001](../adr/0001-cloud-llm.md).
- The server already runs n8n, PostgreSQL, Qdrant and a WhatsApp gateway. **Most of the "brain" infrastructure
  already exists** → [ADR-0002](../adr/0002-n8n-orchestrator.md).
- Several services listen on `0.0.0.0`, and Docker bypasses UFW. That went into the hardening checklist in
  [security.md](../security.md).
- Tailscale was installed but logged out.

## Decisions
1. Cloud LLM, with the n8n agent as the brain and Postgres for tasks/reminders.
2. Remote access only through Tailscale, never public ([ADR-0003](../adr/0003-tailscale.md)).
3. A human-in-the-loop approval for every write action ([ADR-0005](../adr/0005-human-in-the-loop.md)).
4. Desktop mascot in Tauri + Three.js, with an original design ([ADR-0004](../adr/0004-tauri-threejs-desktop.md)).

## Lesson
Checking the hardware before choosing tools saved me from installing a heavy, ready-made stack that would
have competed with the apps already running on the server.

## Next
Tailscale on all devices → `mochi` database → first `mochi-chat` workflow.
