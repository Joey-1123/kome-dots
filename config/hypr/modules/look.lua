-- Look and feel. Colors come from kome.color(), which reads the matugen
-- palette at ~/.config/kome/theme/colors.lua with a built-in fallback.

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,

        col = {
            active_border = {
                colors = { kome.color("primary"), kome.color("tertiary") },
                angle = 45,
            },
            inactive_border = kome.color("outline_variant"),
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = kome.color("shadow"),
        },

        blur = {
            -- Blur renders the whole screen unreadable on this machine
            -- (Intel HD 620, software GL). Off by default; set true on
            -- hardware where the blur pass is handled properly.
            enabled = false,
            size = 4,
            passes = 1,
            vibrancy = 0.0,
            -- xray blurs everything behind the window including the window
            -- itself. Never enable both of these at once.
            xray = false,
        },
    },

    group = {
        col = {
            border_active = kome.color("primary"),
            border_inactive = kome.color("outline_variant"),
        },
        groupbar = {
            col = {
                active = kome.color("primary"),
                inactive = kome.color("outline_variant"),
            },
        },
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    debug = {
        vfr = true,
    },

    cursor = {
        no_warps = true,
        inactive_timeout = 5,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        mfact = 0.55,
    },
})
