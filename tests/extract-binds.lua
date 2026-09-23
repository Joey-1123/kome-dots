-- extract-binds.lua — print every key combo from binds.lua, one per line.
-- Stubs hl/kome so the module loads without Hyprland.
kome = { mainMod = "SUPER", terminal = "kitty", fileManager = "kome-files", menu = "rofi -show drun" }

local calls = {}
-- Recursive stub: any index or call returns the stub itself.
local stub
stub = setmetatable({}, {
    __index = function(_) return stub end,
    __call = function() return stub end,
})
hl = {
    bind = function(key, _, _) table.insert(calls, key) end,
    dsp = stub,
    dispatch = function() end,
    get_active_window = function() return nil end,
    get_active_monitor = function() return nil end,
    get_config = function() return 1.0 end,
    config = function() end,
}

local path = arg[1] or (os.getenv("HOME") .. "/.config/hypr/modules/binds.lua")
dofile(path)
for _, key in ipairs(calls) do
    print(key)
end
