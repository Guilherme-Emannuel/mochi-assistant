# ADR-0001: Use a cloud LLM API instead of a local model

- **Status:** accepted
- **Date:** 2026-10-14

## Context
The original idea was a hybrid setup: a local model for private tasks and the cloud for complex ones.
The home server assessment showed:

- CPU: Intel Core i7-860 (2009, Nehalem). It has **no AVX/AVX2**, which modern llama.cpp/Ollama builds rely on for usable speed.
- GPU: GeForce 9500 GT. It is not supported by current CUDA.
- RAM: 6 GB total, ~3.5 GB available, shared with other services.

Even a 1–3B model would be slow and would compete for memory with the services already running.

## Decision
Use a cloud LLM API with tool-calling for the agent. Keep the integration provider-agnostic
(n8n chat model node), so the provider can change without rewriting workflows.

## Consequences
- Good reasoning quality and fast replies on old hardware.
- Prompts leave the house, so prompts are minimized and no documents or secrets are sent (see security.md).
- Running cost per request; set a monthly spending limit with the provider.
- A local model can come back later on a better machine (e.g. the Windows PC), behind the same interface.

## Alternatives considered
- **Ollama on the server**: rejected because of the hardware.
- **Ollama on the Windows PC**: possible later, but the PC is not always on, so it can't be the main brain.
