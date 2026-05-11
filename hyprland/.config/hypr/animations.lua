hl.config({ animations = { enabled = true } })

-- hl.curve("workspaces", { type = "bezier", points = { { 0.34, 1.26 }, { 0.44, 1 } } })
hl.curve("workspaces", { type = "bezier", points = { { 0.07, 0.91 }, { 0.28, 1 } } })
hl.curve("windows", { type = "bezier", points = { { 0.33, 0.64 }, { 0.28, 1 } } })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "workspaces", style = "slide" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "windows", style = "popin 80%" })
