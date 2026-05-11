local colors = require("colors")

hl.config({
    xwayland = {
        force_zero_scaling = true
    },

    general = {
        border_size = 3,
        col = {
            active_border = {
                colors = { "rgba(" .. colors.primary:sub(5) .. "ee)", "rgba(" .. colors.secondary:sub(5) .. "ee)" },
                angle = 120
            },
            inactive_border = "rgba(" .. colors.primary_container:sub(5) .. "aa)"
        },
        resize_on_border = true,
        gaps_in = 4,
        gaps_out = 8,
        layout = "dwindle",
        allow_tearing = false
    },

    dwindle = {
        preserve_split = true
    },

    misc = {
        force_default_wallpaper = 1,
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true
    },

    debug = {
        vfr = false
    }
})

hl.gesture({
    fingers = 3,
    direction = "horiz",
    action = "workspace",
    args = "m+1, m-1"
})
