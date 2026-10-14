# 04 — The n8n agent (`mochi-chat`)

**Goal:** a webhook that receives a message, runs the AI Agent with tools and returns a reply.
Write actions only create a pending approval.

## Credentials to create in n8n

| Credential | Used by |
|---|---|
| Header Auth: `Authorization: Bearer <token>` (token from `openssl rand -hex 32`) | Webhook node |
| Postgres `mochi_app` | Tools, chat memory |
| LLM provider API key (with a monthly spending limit set on the provider side) | Chat model |
| Google Calendar OAuth2 | Calendar tools (M2) |

## Workflow layout

```
Webhook (POST /mochi, Header Auth)
  └─ AI Agent
       ├─ Chat Model ............ cloud LLM
       ├─ Memory ................ Postgres Chat Memory (table: mochi_chat_history, window: 10)
       ├─ Tool: list_tasks ...... Postgres  → SELECT * FROM tasks_briefing
       ├─ Tool: request_action .. Postgres  → INSERT INTO pending_actions (...) RETURNING id, summary
       └─ Tool: list_events ..... Google Calendar → Get many (M2)
  └─ Respond to Webhook  { reply, pending_action, mood }
```

All writes go through **one** tool, `request_action`. The agent describes what it wants to do,
and a separate workflow (`mochi-approvals`) executes it only after "sim". The LLM never holds a
tool that can change data directly.

### `request_action` query

```sql
INSERT INTO pending_actions (tool, payload, summary, requested_via)
VALUES ($1, $2::jsonb, $3, $4)
RETURNING id, summary;
```

Allowed `tool` values in M1: `create_task`, `complete_task`, `schedule_reminder`.

## System prompt

See [`n8n/prompts/system-prompt.pt-BR.md`](../../n8n/prompts/system-prompt.pt-BR.md).

## Test from the Windows PC (through Tailscale)

```powershell
$h = @{ Authorization = "Bearer $env:MOCHI_WEBHOOK_TOKEN" }
$b = @{ session_id = "desktop"; text = "o que tenho pra hoje?" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "https://<server>.<tailnet>.ts.net/webhook/mochi" -Headers $h -Body $b -ContentType "application/json"
```

Expected result: a reply in Portuguese listing open tasks (or saying there are none).

## Definition of done (M1)

- [ ] "Anota: entregar relatório sexta" → Mochi proposes the task and asks for confirmation
- [ ] "sim" → the task exists in `tasks`, and `audit_log` has the approval and the execution
- [ ] "não" or no answer within 15 min → nothing is created (`rejected` / `expired`)
- [ ] A request without a token gets HTTP 403
