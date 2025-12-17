#!/usr/bin/env bash
set -euo pipefail

PREFIX="/opt/discord-drover"
BIN_LINK="/usr/local/bin/discord-drover"
CONFIG_DIR="/etc/discord-drover"
DESKTOP_DIR="/usr/share/applications"

log() { printf '[install] %s\n' "$*"; }

install -d "$PREFIX"
install -m 755 "$(dirname "$0")/discord-drover.sh" "$PREFIX/discord-drover"

install -d "$CONFIG_DIR"
if [[ ! -f "$CONFIG_DIR/config.env" ]]; then
  install -m 644 "$(dirname "$0")/config.example.env" "$CONFIG_DIR/config.env"
  log "Config placed at $CONFIG_DIR/config.env"
else
  log "Config already exists at $CONFIG_DIR/config.env (left untouched)"
fi
chmod 644 "$CONFIG_DIR/config.env"

ln -sf "$PREFIX/discord-drover" "$BIN_LINK"
log "Installed launcher at $BIN_LINK"

install -d "$DESKTOP_DIR"
install -m 644 "$(dirname "$0")/discord-drover.desktop" "$DESKTOP_DIR/discord-drover.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi
log "Desktop entry installed at $DESKTOP_DIR/discord-drover.desktop"

if command -v systemctl >/dev/null 2>&1; then
  systemctl enable tor.service 2>/dev/null || true
  systemctl enable tor@default.service 2>/dev/null || true
  systemctl restart tor@default.service 2>/dev/null || systemctl start tor@default.service 2>/dev/null || true
fi

log "Done. Edit $CONFIG_DIR/config.env (defaults to Tor SOCKS at 127.0.0.1:9050) and run: discord-drover"
