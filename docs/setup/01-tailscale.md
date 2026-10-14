# 01 — Private network with Tailscale

**Goal:** server, Windows PC and phone in one private network. Mochi is never exposed to the internet.

## 1. Log in the server

Tailscale is already installed on the server (`tailscaled` active, state `NeedsLogin`).

```bash
sudo tailscale up --advertise-tags=tag:server
```

Open the printed login URL **in your own browser** and sign in. Don't share this URL with anyone.

> If the tag is rejected, create the policy in step 3 first (it declares `tag:server`), then run the command again.

Check:

```bash
tailscale status
tailscale ip -4
```

## 2. Join the other devices

- **Windows:** install from tailscale.com/download and sign in with the same account.
- **Phone:** install the Tailscale app and sign in with the same account.

In the admin console (*Machines*), on the server: **Disable key expiry**, so the server doesn't log itself out after 180 days.

## 3. Access policy (ACL)

Admin console → *Access controls*. Minimal policy: only my personal devices can reach the
server, and only on HTTPS (443) and SSH (22).

```jsonc
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"]
  },
  "grants": [
    // My devices → server: HTTPS (Mochi/n8n via tailscale serve) and SSH
    { "src": ["autogroup:member"], "dst": ["tag:server"], "ip": ["tcp:443", "tcp:22"] }
  ]
}
```

Anything not granted is denied. Shared nodes and future guests reach nothing.

## 4. HTTPS for n8n inside the tailnet

Admin console → *DNS*: enable **MagicDNS** and **HTTPS Certificates**. Then, on the server:

```bash
# Publishes local port 5678 as https://<server-name>.<tailnet>.ts.net (tailnet only, NOT public)
sudo tailscale serve --bg 5678
tailscale serve status
```

> `serve` is private to the tailnet. **Do not** use `tailscale funnel`, which makes it public.

## 5. Test

On the phone, **with Wi-Fi off** (mobile data), open `https://<server-name>.<tailnet>.ts.net`.
If the n8n login page appears, the private remote access is working. ✅

## Rollback

```bash
sudo tailscale serve reset   # remove the HTTPS mapping
sudo tailscale down          # disconnect the server from the tailnet
```
