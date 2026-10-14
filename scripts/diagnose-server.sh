#!/usr/bin/env bash
# Read-only server assessment used in M0. Changes nothing.
# Output can contain hostnames and IPs: do NOT commit it (diagnostics-*.txt is git-ignored).
# Usage: bash scripts/diagnose-server.sh | tee diagnostics-$(date +%F).txt
set +e
section() { printf '\n========== %s ==========\n' "$1"; }

section "SYSTEM";   lsb_release -ds 2>/dev/null; uname -r; uptime
section "CPU/RAM";  lscpu | grep -E '^(Model name|CPU\(s\)|Flags)' | sed -E 's/^(Flags:).*/\1 avx: '"$(grep -qw avx /proc/cpuinfo && echo yes || echo no)"', avx2: '"$(grep -qw avx2 /proc/cpuinfo && echo yes || echo no)"'/'; free -h
section "GPU";      lspci 2>/dev/null | grep -Ei 'VGA|3D|Display'
section "DISK";     df -hT -x tmpfs
section "DOCKER";   docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1
                    docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>&1
section "LISTENING TCP PORTS"; ss -lnt
section "TAILSCALE"; tailscale version 2>&1 | head -1; tailscale status 2>&1 | head -20
