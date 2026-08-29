# omarchy_palette.py — live Omarchy theme palette for Nautilus.
#
# nautilus-python runs this module inside the Nautilus process. It installs a
# display-wide Gtk.CssProvider loaded from
#
#     ~/.cache/omarchy/gtk/nautilus.css
#
# and watches that directory. The theme-set.d hook
# ~/.config/omarchy/hooks/theme-set.d/70-omarchy-nautilus-palette.sh
# regenerates the CSS from the active Omarchy theme's colors.toml on every
# `omarchy theme set`, and this provider reloads it in place — every open
# Nautilus window restyles immediately, no restart.

import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Nautilus", "4.1")

from gi.repository import GLib, Gdk, Gio, GObject, Gtk, Nautilus  # noqa: E402

CSS_PATH = os.path.expanduser("~/.cache/omarchy/gtk/nautilus.css")
CSS_DIR = os.path.dirname(CSS_PATH)
CSS_NAME = os.path.basename(CSS_PATH)
RELOAD_DELAY_MS = 80

_provider = None
_monitor = None
_reload_timer_id = None


def _reload_now():
    global _reload_timer_id
    _reload_timer_id = None
    if _provider is None or not os.path.isfile(CSS_PATH):
        return GLib.SOURCE_REMOVE
    try:
        _provider.load_from_file(Gio.File.new_for_path(CSS_PATH))
    except GLib.Error as err:
        print(f"[omarchy-palette] CSS reload failed: {err.message}", flush=True)
    return GLib.SOURCE_REMOVE


def _schedule_reload():
    global _reload_timer_id
    if _reload_timer_id is not None:
        GLib.source_remove(_reload_timer_id)
    _reload_timer_id = GLib.timeout_add(RELOAD_DELAY_MS, _reload_now)


def _on_css_dir_changed(_monitor, changed_file, _other_file, event):
    try:
        name = os.path.basename(changed_file.get_path() or "")
    except Exception:
        return
    if name != CSS_NAME:
        return
    interesting = (
        Gio.FileMonitorEvent.CHANGED,
        Gio.FileMonitorEvent.CREATED,
        Gio.FileMonitorEvent.RENAMED,
        Gio.FileMonitorEvent.CHANGES_DONE_HINT,
    )
    if event in interesting:
        _schedule_reload()


def _install():
    global _provider, _monitor
    display = Gdk.Display.get_default()
    if display is None:
        GLib.timeout_add(200, _install)
        return GLib.SOURCE_REMOVE

    _provider = Gtk.CssProvider()
    if os.path.isfile(CSS_PATH):
        try:
            _provider.load_from_file(Gio.File.new_for_path(CSS_PATH))
        except GLib.Error as err:
            print(f"[omarchy-palette] initial CSS load failed: {err.message}", flush=True)

    # Above STYLE_PROVIDER_PRIORITY_USER (800) so the Omarchy palette outranks
    # ~/.config/gtk-4.0/gtk.css. We only redefine named colors, so widget-level
    # CSS from apps and the Adwaita stylesheet is otherwise untouched.
    Gtk.StyleContext.add_provider_for_display(
        display, _provider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1
    )

    # Watch the directory (not the file): the hook replaces the file with an
    # atomic rename, and directory monitors survive that reliably.
    _monitor = Gio.File.new_for_path(CSS_DIR).monitor_directory(
        Gio.FileMonitorFlags.NONE, None
    )
    _monitor.connect("changed", _on_css_dir_changed)
    print(f"[omarchy-palette] live palette watching {CSS_PATH}", flush=True)
    return GLib.SOURCE_REMOVE


_install()


class OmarchyPalette(GObject.GObject, Nautilus.MenuProvider):
    """Registration shim; the palette wiring happens at import time above."""

    def get_file_actions(self, files):
        return None
