# Roadmap

Each milestone ends with something usable **and** a devlog entry (good material for a LinkedIn post).

## M0 — Foundations
- [x] Server assessment (hardware, running services, ports)
- [x] Architecture, security model, ADRs
- [ ] Tailscale on server, PC and phone, with an ACL
- [ ] `mochi` database + schema v1

## M1 — Text brain (desktop via plain HTTP)
- [ ] `mochi-chat` workflow: AI Agent + `list_tasks` / `create_task` / `complete_task`
- [ ] Approval flow (`pending_actions` + approve/reject)
- [ ] Audit log on every tool call
- [ ] Prompt in pt-BR, with timezone `America/Campo_Grande`
- [ ] Test with `curl` through Tailscale

## M2 — Calendar
- [ ] Google Cloud project + OAuth client (scope `calendar.events`)
- [ ] `list_events`, `create_event` (approval-gated)
- [ ] Conflict check before suggesting a time slot

## M3 — Proactive
- [ ] `mochi-reminders` (every minute, retry on failure)
- [ ] `mochi-briefing` (weekdays 07:00: today's events + overdue/due tasks)
- [ ] WhatsApp channel through Evolution API, only from my own number

## M4 — Mascot
- [ ] Original low-poly mascot in Blender, 4 animations, exported as `.glb`
- [ ] Tauri app: transparent always-on-top window, drag to move, tray icon
- [ ] Chat bubble connected to the webhook
- [ ] Windows notifications for reminders

## M5 — Voice
- [ ] Push-to-talk with a global hotkey → speech-to-text
- [ ] Text-to-speech replies (toggle)

## M6 — Memory & polish
- [ ] Qdrant `mochi_memory` + `save_memory` / `search_memory`
- [ ] Weekly review ("o que ficou pendente?")
- [ ] Demo video + v1.0 release
