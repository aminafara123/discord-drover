#!/usr/bin/env bash
set -euo pipefail

# Lightweight launcher that forces Discord to use a proxy and disables
# non-proxied UDP for WebRTC (pushes voice to TCP/TURN), mirroring the
# Windows drover behavior for Linux.

CONFIG_FILE="${DISCORD_DROVER_CONFIG:-/etc/discord-drover/config.env}"
OVERRIDE_FILE="${DISCORD_DROVER_OVERRIDE:-/tmp/discord-drover/proxy_override}"

log() { printf '[drover] %s\n' "$*" >&2; }
fail() { log "ERROR: $*"; exit 1; }
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Discord Drover" "$*" >/dev/null 2>&1 || true
  fi
}

if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
else
  log "Config not readable at $CONFIG_FILE (chmod 644 $CONFIG_FILE to fix)."
fi

PROXY_URL="${PROXY_URL:-}"
DISABLE_NON_PROXIED_UDP="${DISABLE_NON_PROXIED_UDP:-1}"
EXTRA_FLAGS="${EXTRA_FLAGS:-}"
PROXY_CANDIDATES="${PROXY_CANDIDATES:-}"
mkdir -p "$(dirname "$OVERRIDE_FILE")"

if [[ -f "$OVERRIDE_FILE" ]]; then
  OVERRIDE_PROXY="$(head -n1 "$OVERRIDE_FILE" | tr -d '\r\n')"
  if [[ "$OVERRIDE_PROXY" == "DIRECT" ]]; then
    PROXY_URL=""
    log "Override: direct mode"
    notify "Proxy override: Direct"
  elif [[ -n "$OVERRIDE_PROXY" ]]; then
    PROXY_URL="$OVERRIDE_PROXY"
    log "Override: $PROXY_URL"
    notify "Proxy override: $PROXY_URL"
  fi
fi

check_proxy() {
  local url="$1"
  local hostport="${url#*://}"
  hostport="${hostport#*@}" # strip auth if present
  if [[ "$hostport" == *":"* ]]; then
    local host="${hostport%:*}"
    local port="${hostport##*:}"
    if [[ -n "$host" && "$port" =~ ^[0-9]+$ ]]; then
      timeout 2 bash -c "cat </dev/null >/dev/tcp/$host/$port" 2>/dev/null
      return $?
    fi
  fi
  return 1
}

# If a proxy is set, sanity-check reachability; fall back to direct if unreachable.
if [[ -n "$PROXY_URL" && "${DISCORD_DROVER_SKIP_PROXY_CHECK:-0}" != "1" ]]; then
  if ! check_proxy "$PROXY_URL"; then
    log "Proxy unreachable ($PROXY_URL); falling back to direct mode."
    PROXY_URL=""
  fi
fi

if [[ -z "$PROXY_URL" && -n "$PROXY_CANDIDATES" && "${DISCORD_DROVER_SKIP_PROXY_CHECK:-0}" != "1" ]]; then
  # Try candidates in order; pick the first reachable.
  # shellcheck disable=SC2206
  candidates=( $PROXY_CANDIDATES )
  for candidate in "${candidates[@]}"; do
    if check_proxy "$candidate"; then
      PROXY_URL="$candidate"
      log "Selected proxy from candidates: $PROXY_URL"
      notify "Proxy set to $PROXY_URL"
      break
    else
      log "Candidate proxy unreachable: $candidate"
    fi
  done
fi

find_discord_cmd() {
  if command -v snap >/dev/null 2>&1 && snap list discord >/dev/null 2>&1; then
    echo "snap run discord"
    return 0
  fi

  if command -v discord >/dev/null 2>&1; then
    echo "discord"
    return 0
  fi

  if [[ -x /usr/share/discord/Discord ]]; then
    echo "/usr/share/discord/Discord"
    return 0
  fi

  if [[ -x /usr/lib/discord/Discord ]]; then
    echo "/usr/lib/discord/Discord"
    return 0
  fi

  if command -v flatpak >/dev/null 2>&1 && flatpak info com.discordapp.Discord >/dev/null 2>&1; then
    echo "flatpak run com.discordapp.Discord"
    return 0
  fi

  if [[ -x /opt/Discord/Discord ]]; then
    echo "/opt/Discord/Discord"
    return 0
  fi

  return 1
}

cmd=$(find_discord_cmd) || fail "Discord binary not found (install Discord or adjust DISCORD_CMD)."
if [[ -n "${DISCORD_CMD:-}" ]]; then
  cmd="$DISCORD_CMD"
fi

args=()

if [[ -n "$PROXY_URL" ]]; then
  args+=(--proxy-server="$PROXY_URL" --proxy-bypass-list="<-loopback>")
  log "Proxy set to $PROXY_URL"
else
  log "Proxy not set; running in direct mode."
fi

if [[ "$DISABLE_NON_PROXIED_UDP" == "1" ]]; then
  args+=(--force-webrtc-ip-handling-policy=disable_non_proxied_udp)
  export WEBRTC_DISABLE_NON_PROXIED_UDP=1
  log "Non-proxied UDP disabled; WebRTC forced to TCP/TURN."
fi

if [[ -n "$EXTRA_FLAGS" ]]; then
  # Split EXTRA_FLAGS respecting spaces
  # shellcheck disable=SC2206
  extra=( $EXTRA_FLAGS )
  args+=("${extra[@]}")
fi

args+=(--disable-features=WebRtcHideLocalIpsWithMdns)
args+=(--no-sandbox)

full_cmd=($cmd "${args[@]}" "$@")

if [[ "${DISCORD_DROVER_DRY_RUN:-0}" == "1" ]]; then
  printf '%s\n' "${full_cmd[@]}"
  exit 0
fi

exec "${full_cmd[@]}"
