# Database

PostgreSQL 16. Mochi uses its **own role and database**, so it does not affect other apps on the same server.

| File | Run as | Purpose |
|---|---|---|
| `migrations/000_create_database.sql` | superuser, once | Creates role `mochi_app` and database `mochi` |
| `migrations/001_init_schema.sql` | `mochi_app` | Tables, indexes, triggers, helper functions |

See [docs/setup/02-database.md](../docs/setup/02-database.md) for the step-by-step guide.

## Tables

- **tasks**: to-dos (status `todo → doing → done`, priority 1–4, optional due date).
- **reminders**: persistent reminders; `claim_due_reminders()` picks due rows safely with `FOR UPDATE SKIP LOCKED`.
- **pending_actions**: approval queue for write actions; `expire_pending_actions()` expires stale ones.
- **audit_log**: append-only (a trigger blocks UPDATE and DELETE).
- **tasks_briefing** (view): open tasks bucketed as overdue / today / upcoming.
