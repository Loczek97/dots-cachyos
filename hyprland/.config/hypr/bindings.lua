local vars = require("variables")

-- Modifiers
local mainMod = vars.mainMod:upper()
local shift = "SHIFT"
local alt = "ALT"

-- Sound through pactl
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/scripts/volume.sh up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/scripts/volume.sh down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))

-- Brightness through brightnessctl
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/scripts/brightness.sh up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/scripts/brightness.sh down"))

-- Example binds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(vars.browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + " .. shift .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(vars.menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(vars.emoji))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + " .. shift .. " + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(alt .. " + F4", hl.dsp.exec_cmd("wlogout -b 2"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("quickshell -c hyprquickshot -n"))
hl.bind(mainMod .. " + " .. shift .. " + S", hl.dsp.exec_cmd("quickshell -c hyprquickshot -n"))
hl.bind(mainMod .. " + P", hl.dsp.exec_raw("pseudotile"))
hl.bind(mainMod .. " + R", hl.dsp.exec_raw("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + " .. shift .. " + W", hl.dsp.exec_cmd("~/.config/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/scripts/qs_manager.sh toggle taskmanager"))

-- scrolloverview
hl.bind(mainMod .. " + Tab", hl.dsp.exec_raw("scrolloverview:overview, toggle"))

-- Move focus
local directions = {
    h = "l",
    l = "r",
    k = "u",
    j = "d",
    Left = "l",
    Right = "r",
    Up = "u",
    Down = "d"
}
for key, dir in pairs(directions) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
end

-- Swap windows
local arrows = { Left = "l", Right = "r", Up = "u", Down = "d" }
for key, dir in pairs(arrows) do
    hl.bind(mainMod .. " + " .. shift .. " + " .. key, hl.dsp.window.swap({ direction = dir }))
end

-- Switch workspaces
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    -- Use exec_raw for move_to_workspace as it seems to be missing from dsp.window
    hl.bind(mainMod .. " + " .. shift .. " + " .. key, hl.dsp.exec_raw("movetoworkspace " .. i))
end

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.exec_raw("togglespecialworkspace magic"))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
