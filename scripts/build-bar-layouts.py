"""Build kome-ready waybar layouts from the vendored waybar-themes configs.

Each upstream config.jsonc is a full bar definition: its own module list,
positions, heights, formats, and click handlers. Most of that is portable; the
rest is tied to omarchy:

  * omarchy-only modules (the omarchy menu, the voice-typing status, the omarchy
    update check, the idle and notification-silencing indicators) are dropped,
    because kome has its own equivalents reached from the settings hub;
  * the screen-recording indicator is kept and pointed at kome-record, since kome
    owns recording and the pidfile the indicator reads;
  * click handlers that call omarchy-* scripts are rewritten to the kome script
    or the desktop tool that does the same job, and the rest are dropped so a
    click never runs a command that does not exist;
  * the top-level `width` is dropped, since it is the theme author's screen size
    rather than part of the design.

Everything else - module order, group nesting, heights, margins, spacing,
formats, icons, tooltips - is upstream verbatim, so selecting a theme really does
rearrange the bar instead of only recolouring it.

usage: build-bar-layouts.py <upstream-config-dir> <output-dir> <theme>=<version>...
"""

import json
import os
import re
import sys

# Modules that only make sense on omarchy, with no kome counterpart worth a slot.
DROP = {
    "custom/omarchy",
    "custom/omarchy-theme",
    "custom/omarchy-theme-set",
    "custom/voxtype",
    "custom/idle-indicator",
    "custom/notification-silencing-indicator",
    "custom/music-stopped",
    "custom/waybar-position",
    "custom/update",
    "custom/expand-icon",
}

# kome's recorder replaces omarchy's recording indicator.
REPLACE = {
    "custom/screenrecording-indicator": {
        "exec": "test -f /tmp/kome-gsr.pid && printf 'REC' || printf ''",
        "tooltip": True,
        "tooltip-format": "Toggle screen recording",
        "on-click": "kome-record",
        "on-click-right": "kome-record",
    },
}

# omarchy command -> the kome script or desktop tool with the same job.
CLICKS = {
    "omarchy-menu": "kome-hub-page kome",
    "omarchy-launch-wifi": "kome-hub-page network",
    "omarchy-launch-audio": "kome-hub-page audio",
    "omarchy-launch-bluetooth": "kome-hub-page bluetooth",
    "omarchy-capture-screenrecording": "kome-record",
    "omarchy-toggle-notification-silencing": "kome-notifications toggle",
    "omarchy-theme-set": "kome-theme set",
    "xdg-terminal-exec": "kitty",
    "alacritty": "kitty",
    "pamixer": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
}

# Whatever bar theme is active, a click lands in kome's own UI. Keyed by module
# id; pulseaudio instances (pulseaudio#output) fall back to their base id.
HUB_CLICKS = {
    "network": "kome-hub-page network",
    "bluetooth": "kome-hub-page bluetooth",
    "pulseaudio": "kome-hub-page audio",
    "wireplumber": "kome-hub-page audio",
    "cpu": "kome-hub-page system",
    "memory": "kome-hub-page system",
    "temperature": "kome-hub-page system",
    "disk": "kome-hub-page storage",
    "battery": "kome-hub-page kome",
    "backlight": "kome-brightness toggle",
    "custom/updatespacman": "kome-hub-page updates",
    "custom/update": "kome-hub-page updates",
    "custom/weather": "kome-hub-page display",
}

# Scroll has to do something real too, not just carry upstream's dead handlers.
def scroll_for(name):
    """Scroll handlers per module, or None when scrolling it should do nothing."""
    if name in DECORATIVE or name.startswith("custom/"):
        return None
    if name == "backlight":
        return {
            "on-scroll-up": "kome-brightness up",
            "on-scroll-down": "kome-brightness down",
        }
    if name == "hyprland/workspaces":
        return {
            "on-scroll-up": "kome-workspace next",
            "on-scroll-down": "kome-workspace prev",
        }
    if base_module(name) in ("pulseaudio", "wireplumber"):
        target = "@DEFAULT_AUDIO_SOURCE@" if name.endswith("#input") else "@DEFAULT_AUDIO_SINK@"
        return {
            "on-scroll-up": f"wpctl set-volume -l 125 {target} 5%+",
            "on-scroll-down": f"wpctl set-volume {target} 5%-",
        }
    return None

# Modules kome owns end to end: keep these handlers, drop only omarchy ones.
KOME_OWNED = {
    "custom/mpris",
    "mpris",
    "hyprland/workspaces",
    "hyprland/window",
    "hyprland/submap",
    "tray",
    "clock",
    "idle_inhibitor",
    "power-profiles-daemon",
    "custom/separator",
    "custom/separator2",
    "custom/screenrecording-indicator",
    "group/tray-expander",
}

# click and scroll handlers that are pure decoration upstream.
DECORATIVE = {"custom/weather", "custom/separator", "custom/separator2", "clock", "tray"}


def base_module(name):
    """pulseaudio#output -> pulseaudio; group/left1 -> left1."""
    return name.split("#", 1)[0]


def hub_handler(name, kind):
    if kind == "scroll":
        return scroll_for(name)
    if name in DECORATIVE:
        return None
    if name in HUB_CLICKS:
        return HUB_CLICKS[name]
    # volume sinks and sources route to the audio page too
    if base_module(name) in ("pulseaudio", "wireplumber"):
        return "kome-hub-page audio"
    return None


# Every command a generated layout may run that is not a waybar built-in.
KNOWN = {
    "sh", "bash", "printf", "echo", "test", "date", "sed", "busctl", "python3",
    "playerctl", "notify-send", "which", "kitty", "wpctl", "kome-workspace",
    "kome-record", "kome-notifications", "kome-theme", "kome-updates",
    "kome-hub-page", "kome-brightness", "qs",
}

# Extras the themes expect but that are not part of a base install. Their modules
# get an exec-if guard so the bar stays clean until the package is installed.
OPTIONAL = {"wttrbar", "waybar-module-pacman-updates"}


def load(path):
    """Parse waybar's jsonc: // and /* */ comments outside strings, trailing commas."""
    raw = strip_comments(open(path).read())
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", raw))


def strip_comments(text):
    out = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char == '"':
            end = index + 1
            while end < length:
                if text[end] == "\\":
                    end += 2
                    continue
                if text[end] == '"':
                    end += 1
                    break
                end += 1
            out.append(text[index:end])
            index = end
            continue
        if text.startswith("//", index):
            end = text.find("\n", index)
            index = length if end == -1 else end
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index)
            index = length if end == -1 else end + 2
            continue
        out.append(char)
        index += 1
    return "".join(out)


def filter_modules(modules):
    """Drop the omarchy-only entries; replacements keep their module name and
    bring their own definition when the block is emitted."""
    return [name for name in modules or [] if name not in DROP]


def collect(config):
    """Every module id referenced anywhere, including inside group modules."""
    found = set()
    for key, value in config.items():
        if isinstance(value, list):
            found.update(filter_modules(value))
        elif isinstance(value, dict):
            for slot in ("modules-left", "modules-center", "modules-right"):
                found.update(filter_modules(value.get(slot, [])))
            if key == "group/tray-expander":
                found.update(
                    m for m in value.get("modules", [])
                    if m not in DROP
                )
            else:
                found.update(filter_modules(value.get("modules", [])))
    return found


def rewrite_clicks(config):
    """Strip omarchy launchers, keeping only handlers kome can run."""
    used = set()
    for value in config.values():
        if not isinstance(value, dict):
            continue
        for key in ("on-click", "on-click-right", "on-click-middle"):
            command = value.get(key)
            if not command:
                continue
            first = command.split()[0].split("/")[-1]
            if first in CLICKS:
                value[key] = CLICKS[first]
                used.add(CLICKS[first].split()[0])
            elif first.startswith("omarchy-") or OMARCHY_CALL.search(command):
                # A command that only wraps an omarchy helper is dropped rather
                # than left to fail on click.
                del value[key]
            else:
                used.add(first)
    return used


OMARCHY_CALL = re.compile(r"\bomarchy-[a-z-]+")


def strip_rewrite_modules(block):
    """Drop omarchy entries from window-rewrite maps.

    Upstream uses `window-rewrite` to swap a window's icon for a live module
    (the omarchy voice-typing status). Those keys are module names, so they go
    with the rest of the omarchy-only modules.
    """
    for field in ("window-rewrite", "rewrite"):
        rules = block.get(field)
        if not isinstance(rules, dict):
            continue
        cleaned = {k: v for k, v in rules.items() if k not in DROP}
        if cleaned:
            block[field] = cleaned
        else:
            del block[field]
    return block


def rewrite_handlers(config, used):
    """Point every click and scroll at kome's own UI.

    Upstream sends clicks to omarchy launchers that do not exist here, and
    leaves several modules with no handler at all. Every module kome can speak
    for gets an explicit handler, and omarchy-only ones are stripped, so no
    click can run a command that is not there.
    """
    for key, value in config.items():
        if not isinstance(value, dict) or key not in used:
            continue
        if key == "group/tray-expander":
            continue
        for field in ("on-click", "on-click-right", "on-click-middle",
                      "on-scroll-up", "on-scroll-down"):
            command = value.get(field)
            if not command:
                continue
            first = command.split()[0]
            if (OMARCHY_CALL.search(command)
                    or first.startswith("omarchy-")
                    or (re.match(r"^[a-z]+$", first) and first not in WAYBAR_ACTIONS)):
                del value[field]
        if key not in KOME_OWNED:
            handler = hub_handler(key, "click")
            if handler:
                value["on-click"] = handler
                # Secondary clicks follow the same destination, except the
                # volume mute convention, which stays on the module itself.
                for field in ("on-click-right", "on-click-middle"):
                    command = value.get(field, "")
                    if "wpctl set-mute" in command:
                        target = "@DEFAULT_AUDIO_SOURCE@" if key.endswith("#input") else "@DEFAULT_AUDIO_SINK@"
                        value[field] = f"wpctl set-mute {target} toggle"
                    else:
                        value.pop(field, None)
            elif key not in ("mpris", "custom/mpris"):
                value.pop("on-click", None)
        scroll = hub_handler(key, "scroll") or {}
        for field, command in (("on-scroll-up", scroll.get("on-scroll-up")),
                               ("on-scroll-down", scroll.get("on-scroll-down"))):
            if command:
                value[field] = command
    return config


# waybar's own action tokens are not shell commands: keep them.
WAYBAR_ACTIONS = {
    "activate", "shift+activate", "open", "toggle", "shift_toggle", "mode",
    "next_month", "prev_month", "next_year", "prev_year", "close",
}


def nested_handlers(block):
    """Handler fields nested inside a module block, e.g. clock.calendar."""
    for key, value in block.items():
        if isinstance(value, dict):
            for field in ("on-click", "on-click-right", "on-click-middle",
                          "on-scroll-up", "on-scroll-down"):
                if field in value:
                    yield key, value, field


def strip_foreign_handlers(block):
    """Remove handlers that call omarchy or upstream placeholders.

    A bare lowercase word is a waybar action token (`activate`, `mode`, ...), not
    a command, so those stay; anything else must be a real binary or script.
    """
    for _, holder, field in list(nested_handlers(block)):
        command = holder[field]
        first = command.split()[0]
        if OMARCHY_CALL.search(command) or first.startswith("omarchy-"):
            del holder[field]
    return block


def external_commands(config):
    """The binaries a layout shells out to, ignoring waybar built-ins.

    Only `exec` counts: `exec-if` is a guard (command -v / which), not a
    dependency of its own.
    """
    needed = set()
    for value in config.values():
        if not isinstance(value, dict):
            continue
        command = value.get("exec")
        if not command:
            continue
        binary = command.split()[0].split("/")[-1]
        if binary and binary not in KNOWN:
            needed.add(binary)
    return sorted(needed)


def build(name, version, upstream_dir, out_dir):
    config = load(os.path.join(upstream_dir, version, "config.jsonc"))
    used = collect(config)
    rewrite_clicks(config)
    rewrite_handlers(config, used)

    out = {}
    for key, value in config.items():
        if isinstance(value, list):
            if key in ("modules-left", "modules-center", "modules-right"):
                out[key] = filter_modules(value)
            continue
        if not isinstance(value, dict):
            if key == "width":
                continue
            out[key] = value
            continue
        if key not in used:
            continue
        if key in REPLACE:
            out[key] = dict(REPLACE[key])
            continue
        block = dict(value)
        if "exec" in block and "exec-if" not in block:
            binary = block["exec"].split()[0].split("/")[-1]
            if binary in OPTIONAL:
                block["exec-if"] = f"command -v {binary}"
        for slot in ("modules-left", "modules-center", "modules-right"):
            if slot in block:
                block[slot] = filter_modules(block[slot])
        if key == "group/tray-expander":
            block["modules"] = [m for m in block.get("modules", []) if m not in DROP]
        if "modules" in block:
            block["modules"] = filter_modules(block["modules"])
        out[key] = strip_foreign_handlers(strip_rewrite_modules(block))

    needed = external_commands(out)
    header = [
        f"/* kome layout generated from waybar-themes {version} (MIT), drdeltree.",
        " * Upstream module list, order, and formatting are kept; omarchy-only",
        " * modules and click handlers are replaced or dropped, and the modules that",
        " * need wttrbar or waybar-module-pacman-updates get an exec-if guard so the",
        " * bar stays clean until those packages are installed. Rebuild with",
        " * scripts/build-bar-layouts.py. See THIRD_PARTY_NOTICES.md.",
        f" * kome-bar-theme: needs={','.join(needed) if needed else 'none'} */",
    ]
    body = json.dumps(out, indent=4, ensure_ascii=False)
    path = os.path.join(out_dir, f"{name}.jsonc")
    with open(path, "w") as handle:
        handle.write("\n".join(header) + "\n" + body + "\n")
    return path, needed


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 1
    upstream_dir, out_dir = argv[1], argv[2]
    for pair in argv[3:]:
        name, version = pair.split("=", 1)
        path, needed = build(name, version, upstream_dir, out_dir)
        print(f"{path}: needs {', '.join(needed) if needed else 'nothing extra'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
