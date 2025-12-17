#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${DISCORD_DROVER_CONFIG:-/etc/discord-drover/config.env}"
OVERRIDE_FILE="${DISCORD_DROVER_OVERRIDE:-/tmp/discord-drover/proxy_override}"
LAUNCH_CMD="${DISCORD_DROVER_CMD:-discord-drover}"

if ! command -v zenity >/dev/null 2>&1; then
  echo "zenity is required for the proxy picker." >&2
  exit 1
fi

PROXY_URL=""
PROXY_CANDIDATES=""
if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

rows=()
rows+=("Direct" "DIRECT")

if [[ -n "$PROXY_URL" ]]; then
  rows+=("Default ($PROXY_URL)" "$PROXY_URL")
fi

if [[ -n "$PROXY_CANDIDATES" ]]; then
  # shellcheck disable=SC2206
  candidates=( $PROXY_CANDIDATES )
  for c in "${candidates[@]}"; do
    rows+=("Candidate ($c)" "$c")
  done
fi

choice=$(printf '%s\n' "${rows[@]}" | zenity --list --title="Discord Drover - Select Proxy" \
  --text="Pick a proxy to launch Discord with." \
  --column="Proxy" --column="Value" --hide-column=2 --print-column=2)

if [[ -z "${choice:-}" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$OVERRIDE_FILE")"
printf '%s\n' "$choice" >"$OVERRIDE_FILE"

exec $LAUNCH_CMD "$@"
