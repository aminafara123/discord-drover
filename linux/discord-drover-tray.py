#!/usr/bin/env python3
import os
import shlex
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import Gtk, GLib, AyatanaAppIndicator3  # type: ignore

CONFIG_PATH = os.environ.get("DISCORD_DROVER_CONFIG", "/etc/discord-drover/config.env")
OVERRIDE_PATH = os.environ.get("DISCORD_DROVER_OVERRIDE", "/tmp/discord-drover/proxy_override")
LAUNCH_CMD = os.environ.get("DISCORD_DROVER_CMD", "discord-drover")


def notify(msg: str) -> None:
    try:
        subprocess.Popen(["notify-send", "Discord Drover", msg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def parse_config():
    cfg = {"proxy_url": "", "candidates": []}
    if os.path.isfile(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if line.startswith("PROXY_URL="):
                        cfg["proxy_url"] = line.split("=", 1)[1].strip().strip('"')
                    elif line.startswith("PROXY_CANDIDATES="):
                        vals = line.split("=", 1)[1].strip().strip('"')
                        if vals:
                            cfg["candidates"] = vals.split()
        except Exception:
            pass
    return cfg


def write_override(value: str) -> None:
    os.makedirs(os.path.dirname(OVERRIDE_PATH), exist_ok=True)
    with open(OVERRIDE_PATH, "w", encoding="utf-8") as f:
        f.write(value + "\n")


class Tray:
    def __init__(self) -> None:
        self.cfg = parse_config()
        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "discord-drover-tray",
            "network-workgroup",
            AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS,
        )
        self.indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)
        self.refresh_menu()

    def refresh_menu(self) -> None:
        menu = Gtk.Menu()

        entries = [("Direct", "DIRECT")]
        if self.cfg.get("proxy_url"):
            entries.append((f"Default ({self.cfg['proxy_url']})", self.cfg["proxy_url"]))
        for c in self.cfg.get("candidates", []):
            entries.append((f"Candidate ({c})", c))

        current = self.current_override()
        for label, value in entries:
            display = f"{label}"
            if current == value:
                display = f"✓ {label}"
            item = Gtk.MenuItem(label=display)
            item.connect("activate", self.on_select, value)
            menu.append(item)

        menu.append(Gtk.SeparatorMenuItem())

        launch = Gtk.MenuItem(label="Launch Discord")
        launch.connect("activate", self.on_launch)
        menu.append(launch)

        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.on_quit)
        menu.append(quit_item)

        menu.show_all()
        self.indicator.set_menu(menu)

    def current_override(self) -> str:
        if os.path.isfile(OVERRIDE_PATH):
            try:
                with open(OVERRIDE_PATH, "r", encoding="utf-8") as f:
                    return f.readline().strip()
            except Exception:
                return ""
        return ""

    def on_select(self, _widget, value: str) -> None:
        write_override(value)
        label = "Direct" if value == "DIRECT" else value
        notify(f"Proxy set to {label}")
        self.refresh_menu()

    def on_launch(self, _widget) -> None:
        try:
            subprocess.Popen(shlex.split(LAUNCH_CMD))
        except Exception as e:
            notify(f"Failed to launch Discord: {e}")

    def on_quit(self, _widget) -> None:
        Gtk.main_quit()


def main() -> None:
    Tray()
    Gtk.main()


if __name__ == "__main__":
    Tray()
    Gtk.main()
