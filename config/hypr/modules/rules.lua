-- Window, layer, and workspace rules.

-- Ignore maximize requests from every app.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging with XWayland.
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Float small utility windows.
hl.window_rule({ name = "float-pavucontrol", match = { class = "pavucontrol" }, float = true, size = "900 600", center = true })
hl.window_rule({ name = "float-blueman", match = { class = "blueman-manager" }, float = true, size = "900 600", center = true })
hl.window_rule({ name = "float-nm-editor", match = { class = "nm-connection-editor" }, float = true, size = "900 650", center = true })
hl.window_rule({ name = "float-calc", match = { class = "gnome-calculator" }, float = true, center = true })
hl.window_rule({ name = "float-file-roller", match = { class = "org.gnome.FileRoller" }, float = true, size = "700 500", center = true })

-- Picture-in-picture.
hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, size = "480 270", move = "100%-490 100%-300" })

-- Dim inactive media players.
hl.window_rule({ name = "idle-inhibit-mpv", match = { class = "mpv" }, idle_inhibit = "fullscreen" })

-- Blur the common layer surfaces for glassy popovers.
hl.layer_rule({ name = "blur-bar", match = { namespace = "^(waybar|quickshell)$" }, blur = true })
hl.layer_rule({ name = "blur-launcher", match = { namespace = "^(rofi|wofi|fuzzel|launcher)$" }, blur = true })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "^(swaync|notifications|mako|dunst)$" }, blur = true })

-- hyprland-run popup
hl.window_rule({ name = "move-hyprland-run", match = { class = "hyprland-run" }, move = "20 monitor_h-120", float = true })
