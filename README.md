# Discord Drover (Proxy Settings for Discord)

Discord Drover is a program that forces the Discord application for Windows to use a specified proxy server (HTTP or SOCKS5) for TCP connections (chat, updates). This may be necessary because the original Discord application lacks proxy settings, and the global system proxy is also not used.

Additionally, the program slightly modifies Discord's outgoing UDP traffic, which helps bypass some local restrictions on voice chats.

The program works locally at the specific process level (without drivers) and does not affect the operating system globally. This approach serves as an alternative to using a global VPN (such as TUN interfaces and others).

## Installation

The latest version of the program can be downloaded from the [latest release page](https://github.com/hdrover/discord-drover/releases/latest).

### Automatic Installation

For an easier setup, use the included installer `drover.exe`. Run the program and fill in the proxy settings, then click **Install** to automatically place the necessary files in the correct folder.

In regions like the UAE, where Discord works but voice chat is blocked, you can use **Direct mode** to bypass voice chat restrictions without a proxy.

To uninstall the program and remove all associated files, run `drover.exe` again and click **Uninstall**.

### Manual Installation

If you prefer manual installation, copy the `version.dll` and `drover.ini` files into the folder containing the `Discord.exe` file (not `Update.exe`). The proxy is specified in the `drover.ini` file under the `proxy` parameter.

### Example `drover.ini` Configuration:

```ini
[drover]
; Proxy can use http or socks5 protocols
proxy = http://127.0.0.1:1080

;use-nekobox-proxy = 1
;nekobox-proxy = http://127.0.0.1:2080
```

- **proxy**: Defines the main proxy server to use for Discord (HTTP or SOCKS5). If left empty, no proxy will be used, but UDP manipulation will still occur to bypass voice chat restrictions (same as Direct mode in the installer).
- **use-nekobox-proxy**: Enables the feature to detect if NekoBox is running and use a different proxy if found.
- **nekobox-proxy**: The proxy used when NekoBox is detected, typically `127.0.0.1:2080`.

## Features

- Forces Discord to use a specified proxy for TCP connections.
- Slight interference with UDP traffic for bypassing voice chat restrictions. In Direct mode, no proxy is used, only UDP manipulation is performed.
- Supports HTTP proxies with authentication (login and password).
- No drivers or system-level modifications are required.
- Works locally at the process level, offering an alternative to global VPN solutions.
- Supports Discord Canary and PTB versions in addition to the main version.

## Linux port (Ubuntu 22.04 / Linux Mint 21/22)

This repo now includes a Linux launcher that mirrors Drover’s intent by:
- Forcing Discord through a configured HTTP/SOCKS5 proxy (`--proxy-server`).
- Disabling non-proxied UDP for WebRTC so voice falls back to TCP/TURN (`--force-webrtc-ip-handling-policy=disable_non_proxied_udp` + `WEBRTC_DISABLE_NON_PROXIED_UDP=1`).

### Quick start
```bash
cd linux
sudo ./install.sh               # installs to /opt/discord-drover and /usr/local/bin/discord-drover
sudo nano /etc/discord-drover/config.env  # set PROXY_URL=socks5://host:port or leave empty for direct mode
discord-drover                  # launches Discord with proxy + forced TCP/TURN for voice
```

Config defaults live at `linux/config.example.env`. The launcher auto-detects Discord from snap or .deb installs; override with `DISCORD_CMD=/path/to/Discord` if needed.

Permissions: the installer makes `/etc/discord-drover/config.env` world-readable (no secrets stored there). If you copied configs manually and see “Permission denied,” run `sudo chmod 644 /etc/discord-drover/config.env`.

Binary detection: supports snap, .deb (`discord`), flatpak (`flatpak run com.discordapp.Discord`), and common paths (`/usr/share/discord/Discord`, `/usr/lib/discord/Discord`, `/opt/Discord/Discord`). Use `DISCORD_CMD=... discord-drover` to force a path.

Proxy reachability: the launcher pings the configured proxy (2s) and falls back to direct mode if unreachable. Set `DISCORD_DROVER_SKIP_PROXY_CHECK=1` to skip the check (not recommended unless you’re sure the proxy is up).

### Linux Mint 21/22
- Use the same steps as Ubuntu. Mint is Ubuntu-based, so `sudo ./install.sh` or `sudo apt install ./pkg/discord-drover-linux_<ver>.deb` works out of the box.
- Tested with Mint 21/22 (Cinnamon, X11/Wayland). Voice should route over TCP/TURN when `DISABLE_NON_PROXIED_UDP=1`.

### Build a .deb
```bash
cd linux
VERSION=0.1.0 ./build-deb.sh
sudo apt install ./pkg/discord-drover-linux_0.1.0.deb
```

### Docker (for isolated runs)
```bash
cd linux
docker build -t discord-drover-linux .
docker run --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --net=host \
  -v /dev/snd:/dev/snd --ipc=host \
  -e PROXY_URL="socks5://host:port" \
  discord-drover-linux
```

Note: containerized desktop audio/video may need additional PulseAudio/PipeWire mounts; use host networking for voice.

### Tests
- `linux/tests/dry-run.sh`: ensures required flags and proxy wiring are present.
- `linux/tests/smoke.sh`: checks Discord is installed and launcher composes correctly.

### Troubleshooting
- `Permission denied` reading `/etc/discord-drover/config.env`: ensure it’s readable: `sudo chmod 644 /etc/discord-drover/config.env` (installer sets this by default).
- `Discord binary not found`: run as your regular user (not sudo). If still failing, set `DISCORD_CMD` explicitly, e.g. `DISCORD_CMD="snap run discord" discord-drover` (snap), `DISCORD_CMD="flatpak run com.discordapp.Discord" discord-drover` (flatpak), or point to the binary path.
- Stuck on “Starting” or `ERR_PROXY_CONNECTION_FAILED`: your proxy isn’t reachable. Either clear `PROXY_URL` or point it to a live proxy; the launcher will auto-fallback to direct mode if the proxy check fails. Set `DISCORD_DROVER_SKIP_PROXY_CHECK=1` to disable the preflight.
