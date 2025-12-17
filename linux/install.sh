#!/usr/bin/env bash
set -euo pipefail

PREFIX="/opt/discord-drover"
BIN_LINK="/usr/local/bin/discord-drover"
CONFIG_DIR="/etc/discord-drover"

log() { printf '[install] %s\n' "$*"; }

install -d "$PREFIX"
install -m 755 "$(dirname "$0")/discord-drover.sh" "$PREFIX/discord-drover"

install -d "$CONFIG_DIR"
if [[ ! -f "$CONFIG_DIR/config.env" ]]; then
  install -m 640 "$(dirname "$0")/config.example.env" "$CONFIG_DIR/config.env"
  log "Config placed at $CONFIG_DIR/config.env"
else
  log "Config already exists at $CONFIG_DIR/config.env (left untouched)"
fi

ln -sf "$PREFIX/discord-drover" "$BIN_LINK"
log "Installed launcher at $BIN_LINK"

log "Done. Edit $CONFIG_DIR/config.env and run: discord-drover"
