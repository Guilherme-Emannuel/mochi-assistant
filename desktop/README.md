# Mochi desktop (Tauri 2 + Three.js)

> Planned for milestone M4. See [ADR-0004](../docs/adr/0004-tauri-threejs-desktop.md).

## Behaviour
- Transparent, frameless, always-on-top window (~220×260 px) in a screen corner; drag to move.
- Mascot states: `idle` → `listening` → `thinking` → `talking`, mapped to `.glb` animation clips.
- Click: opens the chat bubble. Global hotkey: push-to-talk.
- Tray icon: show/hide, mute voice, quit.
- Windows notifications for reminders.

## Contract with the server
```http
POST {MOCHI_WEBHOOK_URL}
Authorization: Bearer {MOCHI_WEBHOOK_TOKEN}
Content-Type: application/json

{ "session_id": "desktop", "text": "o que tenho pra hoje?" }
```
Response:
```json
{ "reply": "Hoje você tem…", "pending_action": null, "mood": "happy" }
```
When `pending_action` is set (`{ "id": "...", "summary": "..." }`), the bubble shows **Sim / Não** buttons,
and each one calls the approval webhook.

## Planned structure
```
desktop/
├── src/              TypeScript + Three.js (scene, mascot controller, chat UI)
├── public/models/    mochi.glb (original design, made in Blender)
└── src-tauri/        Rust: window config, tray, global shortcut, notifications
```
