#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-0.1.2}"
NAME="discord-drover-linux"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/linux/pkg/${NAME}_${VERSION}"

rm -rf "$STAGE"
mkdir -p \
  "$STAGE/DEBIAN" \
  "$STAGE/opt/discord-drover" \
  "$STAGE/usr/local/bin" \
  "$STAGE/usr/share/applications" \
  "$STAGE/etc/discord-drover"

install -m 755 "$ROOT/linux/discord-drover.sh" "$STAGE/opt/discord-drover/discord-drover"
install -m 755 "$ROOT/linux/discord-drover-select.sh" "$STAGE/opt/discord-drover/discord-drover-select"
install -m 755 "$ROOT/linux/discord-drover-tray.py" "$STAGE/opt/discord-drover/discord-drover-tray"
install -m 640 "$ROOT/linux/config.example.env" "$STAGE/etc/discord-drover/config.env"
ln -sf /opt/discord-drover/discord-drover "$STAGE/usr/local/bin/discord-drover"
ln -sf /opt/discord-drover/discord-drover-select "$STAGE/usr/local/bin/discord-drover-select"
ln -sf /opt/discord-drover/discord-drover-tray "$STAGE/usr/local/bin/discord-drover-tray"
install -m 644 "$ROOT/linux/discord-drover.desktop" "$STAGE/usr/share/applications/discord-drover.desktop"
install -m 644 "$ROOT/linux/discord-drover-select.desktop" "$STAGE/usr/share/applications/discord-drover-select.desktop"
install -m 644 "$ROOT/linux/discord-drover-tray.desktop" "$STAGE/usr/share/applications/discord-drover-tray.desktop"

cat >"$STAGE/DEBIAN/control" <<EOF
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: bash, tor, torsocks, desktop-file-utils, zenity, python3, python3-gi, gir1.2-ayatanaappindicator3-0.1, python3-pil, libnotify-bin
Maintainer: aminafara123 <aminafara123@gmail.com>
Description: Discord Drover for Linux - proxy + non-UDP WebRTC wrapper
EOF

cat >"$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e

# Ensure Tor is enabled and running for the local SOCKS proxy.
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable tor.service 2>/dev/null || true
  systemctl enable tor@default.service 2>/dev/null || true
  systemctl restart tor@default.service 2>/dev/null || systemctl start tor@default.service 2>/dev/null || true
fi

# Normalize config perms.
if [ -f /etc/discord-drover/config.env ]; then
  chmod 644 /etc/discord-drover/config.env 2>/dev/null || true
fi

# Refresh desktop entries.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi
EOF
chmod 755 "$STAGE/DEBIAN/postinst"

fakeroot dpkg-deb --build "$STAGE"
echo "Built deb: ${STAGE}.deb"
