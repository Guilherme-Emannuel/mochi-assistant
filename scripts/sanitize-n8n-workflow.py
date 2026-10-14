#!/usr/bin/env python3
"""Strip secrets and instance-specific data from an exported n8n workflow before committing.

Usage:
    python3 scripts/sanitize-n8n-workflow.py n8n/workflows/raw/mochi-chat.json n8n/workflows/mochi-chat.json

Removes credential references, pinned test data, static data and instance metadata, and
replaces webhook IDs with stable placeholders. It then scans the result for things that look
like secrets and exits with code 2 if it finds any.
"""
import json
import re
import sys

SECRET_PATTERNS = [
    re.compile(r"(?i)bearer\s+[a-z0-9._\-]{16,}"),
    re.compile(r"\bsk-[A-Za-z0-9_\-]{16,}"),                 # common LLM API key prefix
    re.compile(r"\bAIza[0-9A-Za-z_\-]{30,}"),               # Google API key
    re.compile(r"\bGOCSPX-[0-9A-Za-z_\-]{10,}"),            # Google OAuth client secret
    re.compile(r"\b[0-9a-f]{64}\b"),                        # 32-byte hex tokens
    re.compile(r"\b100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.\d{1,3}\.\d{1,3}\b"),  # Tailscale CGNAT IPs
    re.compile(r"\b192\.168\.\d{1,3}\.\d{1,3}\b"),
    re.compile(r"[a-z0-9\-]+\.ts\.net"),                    # MagicDNS names
]

TOP_LEVEL_DROP = ("pinData", "staticData", "meta", "id", "versionId", "shared", "triggerCount")


def sanitize(wf: dict) -> dict:
    for key in TOP_LEVEL_DROP:
        wf.pop(key, None)
    for i, node in enumerate(wf.get("nodes", [])):
        node.pop("credentials", None)
        if "webhookId" in node:
            node["webhookId"] = f"WEBHOOK_ID_{i}"
    return wf


def find_secrets(text: str) -> list[str]:
    hits = []
    for pat in SECRET_PATTERNS:
        hits += [m.group(0) for m in pat.finditer(text)]
    return hits


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as f:
        wf = json.load(f)
    out = json.dumps(sanitize(wf), indent=2, ensure_ascii=False) + "\n"
    hits = find_secrets(out)
    if hits:
        print("Possible secrets found; fix them in n8n (use credentials/env vars) and re-export:")
        for h in sorted(set(hits)):
            print("  -", h[:6] + "…" if len(h) > 6 else h)
        return 2
    with open(dst, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"OK: {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
