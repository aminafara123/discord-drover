#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-0.1.0}"
NAME="discord-drover-linux"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/linux/pkg/${NAME}_${VERSION}"

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE/opt/discord-drover" "$STAGE/usr/local/bin" "$STAGE/etc/discord-drover"

install -m 755 "$ROOT/linux/discord-drover.sh" "$STAGE/opt/discord-drover/discord-drover"
install -m 640 "$ROOT/linux/config.example.env" "$STAGE/etc/discord-drover/config.env"
ln -sf /opt/discord-drover/discord-drover "$STAGE/usr/local/bin/discord-drover"

cat >"$STAGE/DEBIAN/control" <<EOF
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: bash
Maintainer: aminafara123 <aminafara123@gmail.com>
Description: Discord Drover for Linux - proxy + non-UDP WebRTC wrapper
EOF

fakeroot dpkg-deb --build "$STAGE"
echo "Built deb: ${STAGE}.deb"
