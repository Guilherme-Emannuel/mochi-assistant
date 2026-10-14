# 03 — Google Calendar (OAuth 2.0)

**Goal:** n8n can read events and (after my approval) create them, using OAuth. My Google password is never stored.

## 1. Google Cloud project

1. console.cloud.google.com → **New project** → `mochi-assistant` (a dedicated project, separate from anything else).
2. *APIs & Services → Library* → enable **Google Calendar API**.

## 2. OAuth consent screen

1. *Google Auth Platform → Branding*: app name `Mochi`, your email as support and developer contact.
2. *Audience*: **External**. Add your own Gmail as a test user.
3. *Data access*: add the scope `https://www.googleapis.com/auth/calendar.events`.

> ⚠️ While the app is in **Testing**, Google refresh tokens expire after **7 days**, and you'd have to reconnect every week.
> For a personal app, click **Publish app**. It stays unverified, so you'll see a "Google hasn't verified this app"
> warning when connecting. That's expected, because you are the developer and the only user.

## 3. OAuth client

*Clients → Create client* → type **Web application**.

The redirect URI must match exactly what n8n shows in the credential dialog
("OAuth Redirect URL"). Pick one option:

| Option | Redirect URI | Notes |
|---|---|---|
| A. SSH tunnel (simplest) | `http://localhost:5678/rest/oauth2-credential/callback` | Open n8n through `ssh -L 5678:localhost:5678 <user>@<server>` and browse to `http://localhost:5678` |
| B. Tailscale HTTPS | `https://<server>.<tailnet>.ts.net/rest/oauth2-credential/callback` | Requires n8n's `WEBHOOK_URL` / editor base URL set to that address |

Download nothing to the repo. Copy the **Client ID** and **Client secret** straight into n8n.

## 4. n8n credential — scope trade-off

| Approach | Scope | Trade-off |
|---|---|---|
| Built-in **Google Calendar OAuth2** credential + Google Calendar node | Defined by n8n (may include full `calendar`) | Easiest, but broader access |
| Generic **OAuth2 API** credential + HTTP Request nodes | `calendar.events` only | Least privilege, but you write the API calls yourself |

Mochi starts with the **built-in node** for speed (M2), and the scope it requests is recorded in the devlog.
Moving to the least-privilege HTTP approach is tracked as a hardening task.

## 5. Test

In a test workflow: Google Calendar node → *Event → Get many* → time range = today. You should see today's events.

## Revoke access

myaccount.google.com → *Security → Third-party connections* → Mochi → **Remove access**.
