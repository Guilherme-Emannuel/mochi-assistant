# Security model

Mochi can read my calendar and act on my behalf, so security is a requirement and not an afterthought.

## Threat model (short)

| Threat | Mitigation |
|---|---|
| Someone on the internet reaches n8n or the databases | No public ports for Mochi. Access only through the Tailscale tailnet, with ACLs |
| A device on my LAN reaches services | Bind services to `127.0.0.1` / the Tailscale IP (see hardening checklist) |
| LLM misreads a request, or a prompt injection (e.g. text inside a calendar event) makes it do something | **Every write action needs my explicit approval**. The agent only queues a `pending_action` |
| Stolen webhook URL | Bearer token on the webhook plus Tailscale-only reachability |
| Leaked Google credentials | OAuth with minimal scopes, a dedicated Google Cloud project and revocable tokens. My Google password is never stored |
| Secrets committed to git | `.gitignore`, `.env.example` only, and `scripts/sanitize-n8n-workflow.py` before committing workflows |
| Silent misuse | Append-only `audit_log` of every action |
| Data sent to the LLM provider | Send only what each request needs. No documents and no passwords in prompts |

## Principles

1. **Read freely, write with permission.** Read-only tools run directly. Tools that create,
   change, delete or send are approval-gated, and pending actions expire after 15 minutes.
2. **Least privilege.**
   - Postgres: dedicated role `mochi_app` that only owns the `mochi` database.
   - Google: the narrowest scope that works (target: `calendar.events`). The trade-off is documented in [setup/03](setup/03-google-calendar.md).
   - Qdrant: dedicated collection, plus an API key enabled.
3. **No public surface.** Mochi endpoints are never published through a reverse proxy or a
   Cloudflare tunnel.
4. **Secrets live only on the server** (n8n credentials store / `.env`), never in the repo or in the desktop binary.
5. **Untrusted content is data.** Calendar event descriptions, WhatsApp messages from other
   people and web content are never treated as instructions. The system prompt says so explicitly.

## Hardening checklist (home server)

- [ ] Tailscale logged in, with an ACL that allows only my devices to reach the server ([guide](setup/01-tailscale.md))
- [ ] Router: confirm that no database or admin port is forwarded to the internet
- [ ] Qdrant: enable an API key (`QDRANT__SERVICE__API_KEY`)
- [ ] Rebind database ports (`5432`, `3306`, `6333`) from `0.0.0.0` to `127.0.0.1` in their compose files.
      Docker publishes ports **past UFW**, so a firewall rule alone is not enough
- [ ] n8n: owner account with a strong password, user management on, and a recent version pinned instead of `latest`
- [ ] Webhook token is generated with `openssl rand -hex 32` and rotated if it leaks
- [ ] Backups of the `mochi` database go to the backup disk

> Changes to existing containers are planned and applied one at a time, with a rollback, and are
> documented in the devlog. They are out of scope for the first milestone.

## What is safe to publish

| ✅ Publish | ❌ Never publish |
|---|---|
| Schema, docs, sanitized workflows | `.env`, OAuth client secrets, tokens |
| Generic hardware specs | Public IP, Tailscale IPs, MagicDNS names, LAN layout |
| Screenshots with blurred data | Raw diagnostics output, real calendar/task contents |
