local colors = {}

-- ============================================
-- BASE COLORS (backgrounds)
-- ============================================
colors.base = "0xff{{colors.surface.default.hex_stripped}}"
colors.baseAlpha = "{{colors.surface.default.hex_stripped}}"

colors.mantle = "0xff{{colors.surface_dim.default.hex_stripped}}"
colors.mantleAlpha = "{{colors.surface_dim.default.hex_stripped}}"

colors.crust = "0xff{{colors.surface_container_lowest.default.hex_stripped}}"
colors.crustAlpha = "{{colors.surface_container_lowest.default.hex_stripped}}"

colors.surface0 = "0xff{{colors.surface_container_low.default.hex_stripped}}"
colors.surface0Alpha = "{{colors.surface_container_low.default.hex_stripped}}"

colors.surface1 = "0xff{{colors.surface_container.default.hex_stripped}}"
colors.surface1Alpha = "{{colors.surface_container.default.hex_stripped}}"

colors.surface2 = "0xff{{colors.surface_variant.default.hex_stripped}}"
colors.surface2Alpha = "{{colors.surface_variant.default.hex_stripped}}"

-- ============================================
-- OVERLAY COLORS
-- ============================================
colors.overlay0 = "0xff{{colors.surface_variant.default.hex_stripped}}"
colors.overlay0Alpha = "{{colors.surface_variant.default.hex_stripped}}"

colors.overlay1 = "0xff{{colors.outline_variant.default.hex_stripped}}"
colors.overlay1Alpha = "{{colors.outline_variant.default.hex_stripped}}"

colors.overlay2 = "0xff{{colors.outline.default.hex_stripped}}"
colors.overlay2Alpha = "{{colors.outline.default.hex_stripped}}"

-- ============================================
-- TEXT COLORS
-- ============================================
colors.text = "0xff{{colors.on_surface.default.hex_stripped}}"
colors.textAlpha = "{{colors.on_surface.default.hex_stripped}}"

colors.subtext0 = "0xff{{colors.outline.default.hex_stripped}}"
colors.subtext0Alpha = "{{colors.outline.default.hex_stripped}}"

colors.subtext1 = "0xff{{colors.on_surface_variant.default.hex_stripped}}"
colors.subtext1Alpha = "{{colors.on_surface_variant.default.hex_stripped}}"

-- ============================================
-- ACCENT COLORS (from wallpaper!)
-- ============================================
colors.primary = "0xff{{colors.primary.default.hex_stripped}}"
colors.primaryAlpha = "{{colors.primary.default.hex_stripped}}"

colors.secondary = "0xff{{colors.secondary.default.hex_stripped}}"
colors.secondaryAlpha = "{{colors.secondary.default.hex_stripped}}"

colors.tertiary = "0xff{{colors.tertiary.default.hex_stripped}}"
colors.tertiaryAlpha = "{{colors.tertiary.default.hex_stripped}}"

colors.primary_container = "0xff{{colors.primary_container.default.hex_stripped}}"
colors.primary_containerAlpha = "{{colors.primary_container.default.hex_stripped}}"

colors.secondary_container = "0xff{{colors.secondary_container.default.hex_stripped}}"
colors.secondary_containerAlpha = "{{colors.secondary_container.default.hex_stripped}}"

colors.tertiary_container = "0xff{{colors.tertiary_container.default.hex_stripped}}"
colors.tertiary_containerAlpha = "{{colors.tertiary_container.default.hex_stripped}}"

colors.error = "0xff{{colors.error.default.hex_stripped}}"
colors.errorAlpha = "{{colors.error.default.hex_stripped}}"

colors.error_container = "0xff{{colors.error_container.default.hex_stripped}}"
colors.error_containerAlpha = "{{colors.error_container.default.hex_stripped}}"

-- ============================================
-- CATPPUCCIN-STYLE ALIASES
-- ============================================
colors.lavender = "0xff{{colors.on_surface.default.hex_stripped}}"
colors.lavenderAlpha = "{{colors.on_surface.default.hex_stripped}}"

colors.blue = "0xff{{colors.primary.default.hex_stripped}}"
colors.blueAlpha = "{{colors.primary.default.hex_stripped}}"

colors.sapphire = "0xff{{colors.on_primary_container.default.hex_stripped}}"
colors.sapphireAlpha = "{{colors.on_primary_container.default.hex_stripped}}"

colors.sky = "0xff{{colors.tertiary.default.hex_stripped}}"
colors.skyAlpha = "{{colors.tertiary.default.hex_stripped}}"

colors.teal = "0xff{{colors.on_tertiary_container.default.hex_stripped}}"
colors.tealAlpha = "{{colors.on_tertiary_container.default.hex_stripped}}"

colors.green = "0xff{{colors.on_secondary_container.default.hex_stripped}}"
colors.greenAlpha = "{{colors.on_secondary_container.default.hex_stripped}}"

colors.yellow = "0xff{{colors.on_primary_container.default.hex_stripped}}"
colors.yellowAlpha = "{{colors.on_primary_container.default.hex_stripped}}"

colors.peach = "0xff{{colors.on_tertiary_container.default.hex_stripped}}"
colors.peachAlpha = "{{colors.on_tertiary_container.default.hex_stripped}}"

colors.maroon = "0xff{{colors.on_error_container.default.hex_stripped}}"
colors.maroonAlpha = "{{colors.on_error_container.default.hex_stripped}}"

colors.red = "0xff{{colors.on_error_container.default.hex_stripped}}"
colors.redAlpha = "{{colors.on_error_container.default.hex_stripped}}"

colors.mauve = "0xff{{colors.secondary.default.hex_stripped}}"
colors.mauveAlpha = "{{colors.secondary.default.hex_stripped}}"

colors.pink = "0xff{{colors.tertiary.default.hex_stripped}}"
colors.pinkAlpha = "{{colors.tertiary.default.hex_stripped}}"

colors.flamingo = "0xff{{colors.on_error_container.default.hex_stripped}}"
colors.flamingoAlpha = "{{colors.on_error_container.default.hex_stripped}}"

colors.rosewater = "0xff{{colors.on_tertiary_container.default.hex_stripped}}"
colors.rosewaterAlpha = "{{colors.on_tertiary_container.default.hex_stripped}}"

return colors
