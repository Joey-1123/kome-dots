-- Autostart. The selected components are launched by kome-session, which reads
-- ~/.config/kome/providers.env so this file stays provider-agnostic.
hl.on("hyprland.start", function()
    hl.exec_cmd("kome-session start")
end)
