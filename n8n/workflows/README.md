# n8n workflows

Sanitized exports of Mochi's workflows. **Never commit raw exports.**

| Workflow | Status |
|---|---|
| `mochi-chat.json` | planned (M1) |
| `mochi-approvals.json` | planned (M1) |
| `mochi-reminders.json` | planned (M3) |
| `mochi-briefing.json` | planned (M3) |

## Export → commit

```bash
# 1. In n8n: Workflow menu → Download → save into n8n/workflows/raw/ (git-ignored)
# 2. Sanitize:
python3 scripts/sanitize-n8n-workflow.py n8n/workflows/raw/mochi-chat.json n8n/workflows/mochi-chat.json
# 3. Review the diff, then commit
```

After importing, reconnect the credentials (Postgres `mochi_app`, Google Calendar OAuth, LLM provider) in the n8n UI.
