local function set(cat, key, val)
    hl.config({ [cat] = { [key] = val } })
end

set("animations", "enabled", true)

hl.curve("workspaces", { type = "bezier", points = { { 0.34, 1.26 }, { 0.44, 1 } } })
hl.curve("windows", { type = "bezier", points = { { 0.35, 1.14 }, { 0.44, 1 } } })

hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "workspaces", style = "slidefade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "windows", style = "popin 70%" })
