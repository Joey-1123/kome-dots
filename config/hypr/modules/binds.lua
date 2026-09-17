-- kome — keybinds. Enhanced with patterns from 43PR/dotfiles.
-- SUPER = mainMod (Windows key)

local m = kome.mainMod
local term = kome.terminal
local fm   = kome.fileManager
local menu = kome.menu
local browser = "kome-browser"

-- Launchers ----------------------------------------------------------------
hl.bind(m .. " + T", hl.dsp.exec_cmd(term))
hl.bind(m .. " + D", hl.dsp.exec_cmd("pgrep -x rofi >/dev/null && pkill -x rofi || " .. menu))
hl.bind(m .. " + E", hl.dsp.exec_cmd(fm))
hl.bind(m .. " + B", hl.dsp.exec_cmd(browser))

-- Window management --------------------------------------------------------
hl.bind(m .. " + Q", hl.dsp.window.close())
hl.bind(m .. " + F", hl.dsp.window.fullscreen())
hl.bind(m .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(m .. " + SPACE", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    -- Auto-center floated windows (from 43PR)
    local w = hl.get_active_window()
    if w ~= nil and w.floating then
        local mon = hl.get_active_monitor()
        if mon ~= nil then
            local target_w = math.floor(mon.width * 0.7)
            local target_h = math.floor(mon.height * 0.7)
            hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h, relative = false }))
            local mon_x = mon.x or 0
            local mon_y = mon.y or 0
            local target_x = mon_x + math.floor((mon.width - target_w) / 2)
            local target_y = mon_y + math.floor((mon.height - target_h) / 2)
            hl.dispatch(hl.dsp.window.move({ x = target_x, y = target_y, relative = false }))
        end
    end
end)
hl.bind(m .. " + P", hl.dsp.window.pseudo())
hl.bind(m .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(m .. " + C", hl.dsp.window.center())

-- Opacity toggle (from 43PR) -----------------------------------------------
hl.bind(m .. " + O", hl.dsp.exec_cmd("kome-opacity"))

-- Power menu ---------------------------------------------------------------
hl.bind(m .. " + GRAVE", hl.dsp.exec_cmd("kome-powermenu"))
hl.bind(m .. " + TAB", hl.dsp.exec_cmd("kome-lock"))

-- Clipboard ----------------------------------------------------------------
hl.bind(m .. " + V", hl.dsp.exec_cmd("kome-clipboard"))

-- Screenshots --------------------------------------------------------------
hl.bind("Print", hl.dsp.exec_cmd("kome-screenshot region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("kome-screenshot full"))
hl.bind(m .. " + Print", hl.dsp.exec_cmd("kome-screenshot window"))

-- Focus (vim-style H/J/K/L) ------------------------------------------------
hl.bind(m .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(m .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(m .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(m .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move window (vim-style) --------------------------------------------------
hl.bind(m .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(m .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(m .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(m .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Resize window (vim-style, repeating) ------------------------------------
hl.bind(m .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0 }), { repeating = true })
hl.bind(m .. " + CTRL + L", hl.dsp.window.resize({ x = 40, y = 0 }), { repeating = true })
hl.bind(m .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -40 }), { repeating = true })
hl.bind(m .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 40 }), { repeating = true })

-- Workspaces 1-10 ----------------------------------------------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(m .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(m .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mouse move/resize --------------------------------------------------------
hl.bind(m .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Toggle bar ---------------------------------------------------------------
hl.bind(m .. " + SHIFT + B", hl.dsp.exec_cmd("kome-bar toggle"))

-- Theme toggle -------------------------------------------------------------
hl.bind(m .. " + SHIFT + T", hl.dsp.exec_cmd("kome-theme toggle"))

-- Wallpaper picker ---------------------------------------------------------
hl.bind(m .. " + W", hl.dsp.exec_cmd("kome-wallpaper pick"))

-- Brightness ---------------------------------------------------------------
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("kome-osd brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("kome-osd brightness-down"), { locked = true, repeating = true })

-- Keyboard layout ----------------------------------------------------------
hl.bind(m .. " + X", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))

-- Zoom (mouse wheel + keypad) ----------------------------------------------
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 1.5 then
        hl.config({ cursor = { zoom_factor = 1.5 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(m .. " + mouse_down", function() zoomfunction(-0.5) end, { repeating = true })
hl.bind(m .. " + mouse_up",   function() zoomfunction(0.5) end,  { repeating = true })
hl.bind(m .. " + code:82",    function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(m .. " + code:86",    function() zoomfunction(0.3) end,  { repeating = true })

-- Exit (use hyprshutdown if available) -------------------------------------
hl.bind(m .. " + SHIFT + E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))

-- Media keys ---------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("kome-osd volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("kome-osd volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("kome-osd volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),     { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"), { locked = true })