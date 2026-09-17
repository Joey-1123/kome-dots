-- Monitors. The empty output "" is the wildcard, so any connected display gets
-- a working default with no per-machine configuration.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

-- Optional per-machine monitor layout, untracked. See monitors.local.lua.example.
pcall(require, "modules.monitors.local")
