-- Environment variables applied by Hyprland at start.
-- Kept hardware-agnostic: no GPU-specific variables here. Put those in the
-- untracked modules/local.lua (for example AQ_DRM_DEVICES for multi-GPU).

-- cursors
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")

-- toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
hl.env("SDL_VIDEODRIVER", "wayland")

-- electron / chromium / firefox on wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- java
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
