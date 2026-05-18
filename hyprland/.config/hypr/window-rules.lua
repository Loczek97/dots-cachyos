-- ─────────────────────────────
-- Global rules
-- ─────────────────────────────
hl.window_rule({ match = { class = "CachyOSHello" }, float = true })
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
-- Global opacity (0.95)
hl.window_rule({ match = { class = ".*" }, opacity = 0.95 })
hl.window_rule({ match = { class = "gimp" }, no_blur = true, opacity = "1.0 override" })
hl.window_rule({ match = { class = "Minecraft" }, no_blur = true, opacity = "1.0 override" })
hl.window_rule({ match = { title = "Lunar Client.*" }, no_blur = true, opacity = "1.0 override" })
hl.window_rule({ match = { class = "Better MC" }, no_blur = true, opacity = "1.0 override" })

hl.window_rule({ match = { class = "discord-canary" }, opacity = 0.875 })

-- ─────────────────────────────
-- Layer rules (OSD / overlays)
-- ─────────────────────────────
hl.layer_rule({ match = { namespace = "volume_osd" }, no_anim = true })
hl.layer_rule({ match = { namespace = "brightness_osd" }, no_anim = true })
hl.layer_rule({ match = { namespace = "music_win" }, no_anim = true })
hl.layer_rule({ match = { namespace = "usb_popup" }, no_anim = true })
hl.layer_rule({ match = { namespace = "calendar_win" }, no_anim = true })
hl.layer_rule({ match = { namespace = "network_win" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

-- ───────── Steam Games (General) ─────────
hl.window_rule({ match = { class = "steam_app_.*" }, immediate = true, opacity = "1.0 override", no_blur = true, fullscreen = true })

-- ───────── Gamescope ─────────
hl.window_rule({ match = { class = "gamescope" }, immediate = true, opacity = "0.5 override", no_blur = true, fullscreen = true })

-- ───────── CS2 ─────────
hl.window_rule({ match = { class = "cs2" }, immediate = true, keep_aspect_ratio = true, opacity = "1.0 override", no_blur = true })

-- ───────── Wallpaper Picker ─────────
hl.window_rule({
    match = { title = "wallpaper-picker" },
    float = true,
    center = true,
    size = { 1920, 500 },
    opacity =
    "1.0 override",
    no_blur = true,
    border_size = 0
})

-- ───────── Battery Popup ─────────
hl.window_rule({
    match = { title = "battery-popup" },
    float = true,
    pin = true,
    size = { 480, 760 },
    move = { "100%-500", "70" },
    opacity =
    "1.0 override",
    rounding = 20,
    no_blur = true
})

-- ───────── Network Popup ─────────
hl.window_rule({
    match = { title = "network-popup" },
    float = true,
    pin = true,
    size = { 900, 700 },
    move = { "100%-920", "70" },
    opacity =
    "1.0 override",
    rounding = 20,
    no_blur = true
})

-- ───────── Music Window ─────────
hl.window_rule({
    match = { title = "music_win" },
    float = true,
    pin = true,
    size = { 700, 280 },
    move = { "12", "70" },
    opacity =
    "1.0 override",
    rounding = 20,
    no_blur = true
})

-- ───────── Calendar Window ─────────
hl.window_rule({
    match = { title = "calendar_win" },
    float = true,
    pin = true,
    size = { 1300, 500 },
    move = { "310", "70" },
    opacity =
    "1.0 override",
    rounding = 20,
    no_blur = true
})

-- ───────── Task manager ─────────
hl.window_rule({
    match = { title = "taskmanager_win" },
    float = true,
    pin = true,
    size = { 900, 1000 },
    opacity =
    "1.0 override",
    rounding = 20,
    no_blur = true
})

-- ───────── Mixer Popup ─────────
hl.window_rule({ match = { title = "mixer_win" }, float = true, pin = true, size = { 650, 700 }, opacity = "1.0 override", rounding = 20, no_blur = true, move = { "1255", "70" } })

-- ───────── Notification widget ─────────
hl.layer_rule({ match = { namespace = "qs-notification-center" }, no_anim = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "qs-popups" }, no_anim = true })

-- ───────── Launcher layer ─────────
hl.layer_rule({ match = { namespace = "launcher" } })

-- ───────── Jetbrains IDEs ─────────
hl.window_rule({ match = { class = "jetbrains-.*" }, no_initial_focus = true, no_anim = true })

-- ───────── Jetbrains Toolbox App ─────────
hl.window_rule({
    match = { class = "jetbrains-toolbox" },
    float = true,
    pin = true,
    size = { 430, 670 },
    move = { "1480", "260" },
    no_anim = true
})