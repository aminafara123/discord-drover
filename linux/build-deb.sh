#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-0.1.0}"
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
install -m 640 "$ROOT/linux/config.example.env" "$STAGE/etc/discord-drover/config.env"
ln -sf /opt/discord-drover/discord-drover "$STAGE/usr/local/bin/discord-drover"
install -m 644 "$ROOT/linux/discord-drover.desktop" "$STAGE/usr/share/applications/discord-drover.desktop"

cat >"$STAGE/DEBIAN/control" <<EOF
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: bash, tor, torsocks, desktop-file-utils
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
