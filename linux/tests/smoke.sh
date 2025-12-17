#!/usr/bin/env bash
set -euo pipefail

echo "[smoke] Checking discord presence..."
if command -v discord >/dev/null 2>&1 || (command -v snap >/dev/null 2>&1 && snap list discord >/dev/null 2>&1) || [[ -x /usr/share/discord/Discord ]] || [[ -x /usr/lib/discord/Discord ]]; then
  echo "[smoke] Discord binary found."
else
  echo "[smoke] Discord not found; install discord package first." >&2
  exit 1
fi

echo "[smoke] Running dry-run..."
DIR="$(cd "$(dirname "$0")/.." && pwd)"
DISCORD_DROVER_DRY_RUN=1 "$DIR/discord-drover.sh" >/dev/null
echo "[smoke] OK"
