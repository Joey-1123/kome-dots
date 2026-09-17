-- kome — Hyprland configuration entry point
-- Lua config; requires Hyprland >= 0.55 (developed against 0.56).
--
-- Layout:
--   hyprland.lua           this file
--   modules/*.lua          required config modules
--   modules/local.lua      optional, untracked machine overrides (loaded last)
--   modules/monitors.local.lua  optional, untracked monitor overrides
--
-- The palette lives outside the tree at ~/.config/kome/theme/colors.lua and is
-- written by matugen. It is added to package.path so the config watcher tracks
-- it; `kome-theme` also runs `hyprctl reload` after regenerating.

kome = {
    mainMod = "SUPER",
    terminal = "kitty",
    fileManager = "kome-files",
    menu = "rofi -show drun",
}

-- Fallback palette, used before the first matugen run and for any key a scheme
-- does not provide.
kome.fallback = {
    background = "rgba(141414ff)",
    on_background = "rgba(e6e6e6ff)",
    surface = "rgba(1a1a1aff)",
    on_surface = "rgba(e6e6e6ff)",
    surface_variant = "rgba(2a2a2aff)",
    on_surface_variant = "rgba(b0b0b0ff)",
    primary = "rgba(d0d0d0ff)",
    on_primary = "rgba(1a1a1aff)",
    primary_container = "rgba(3a3a3aff)",
    on_primary_container = "rgba(e6e6e6ff)",
    secondary = "rgba(a0a0a0ff)",
    tertiary = "rgba(808080ff)",
    error = "rgba(ff6b6bff)",
    outline = "rgba(5a5a5aff)",
    outline_variant = "rgba(3a3a3aff)",
    shadow = "rgba(00000066)",
    scrim = "rgba(00000099)",
    inverse_surface = "rgba(e6e6e6ff)",
    inverse_on_surface = "rgba(1a1a1aff)",
    inverse_primary = "rgba(3a3a3aff)",
}

local HOME = os.getenv("HOME") or ""
package.path = package.path .. ";" .. HOME .. "/.config/kome/theme/?.lua"

local ok, colors = pcall(require, "colors")
kome.colors = {}
if ok and type(colors) == "table" then
    for key, value in pairs(colors) do
        kome.colors[key] = value
    end
end

--- Resolve a palette key with fallback.
function kome.color(key)
    return kome.colors[key] or kome.fallback[key] or "rgba(ffffffff)"
end

require("modules.env")
require("modules.monitors")
require("modules.look")
require("modules.animations")
require("modules.input")
require("modules.binds")
require("modules.rules")
require("modules.autostart")

pcall(require, "modules.local")
