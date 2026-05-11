local function set(cat, key, val)
    hl.config({ [cat] = { [key] = val } })
end

set("input", "kb_layout", "pl")
set("input", "kb_variant", "")
set("input", "kb_model", "")
set("input", "kb_options", "")
set("input", "kb_rules", "")

set("input", "follow_mouse", 1)

set("input", "touchpad", {
    natural_scroll = true,
    tap_to_click = true,
    tap_and_drag = true
})

set("input", "sensitivity", 0)
