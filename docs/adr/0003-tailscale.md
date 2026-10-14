# ADR-0003: Remote access through Tailscale only

- **Status:** accepted
- **Date:** 2026-10-14

## Context
I want to use Mochi from my phone outside home. The server already has a reverse proxy and a
Cloudflare tunnel for public apps, but an assistant with access to my calendar should not be public.

## Decision
Mochi endpoints are reachable only inside my Tailscale tailnet. ACLs allow only my own devices.
HTTPS comes from `tailscale serve` with a MagicDNS certificate.

## Consequences
- No open ports and no public attack surface.
- Every client device needs Tailscale installed and logged in.
- WhatsApp is the exception: it goes through the Evolution API, and only messages from my own number are accepted.
