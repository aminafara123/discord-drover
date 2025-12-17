#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export DISCORD_DROVER_DRY_RUN=1
export DISCORD_DROVER_SKIP_PROXY_CHECK=1
export DISABLE_NON_PROXIED_UDP=1
export PROXY_URL="socks5://127.0.0.1:1080"

cmd=$("$SCRIPT_DIR/discord-drover.sh")

echo "Dry-run command:"
echo "$cmd"

[[ "$cmd" == *"--force-webrtc-ip-handling-policy=disable_non_proxied_udp"* ]] || { echo "missing webrtc flag"; exit 1; }
[[ "$cmd" == *"--proxy-server="* ]] || { echo "missing proxy flag"; exit 1; }
echo "OK"
