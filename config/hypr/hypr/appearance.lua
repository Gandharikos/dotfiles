local M = {}

function M.setup(ctx)
  local theme = ctx.theme or {}

  hl.config({
    decoration = {
      rounding = 14,
      rounding_power = 2.0,
      active_opacity = 0.94,
      inactive_opacity = 0.88,
      fullscreen_opacity = 1.0,
      dim_inactive = false,
      dim_special = 0.35,
      dim_around = 0.4,
      blur = {
        enabled = true,
        size = 10,
        passes = 3,
        ignore_opacity = true,
        new_optimizations = true,
        xray = true,
        vibrancy = 0.25,
        popups = true,
        popups_ignorealpha = 0.1,
      },
      shadow = {
        enabled = true,
        color = theme.shadow,
        range = 4,
        render_power = 4,
        offset = { 1, 1 },
        scale = 0.97,
      },
    },
    animations = {
      enabled = true,
    },
  })

  hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
  hl.curve("smooth", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
  hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
  hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

  hl.animation({ leaf = "global", enabled = true, speed = 9, bezier = "smooth" })
  hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "easy" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "easy", style = "popin 82%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "linear", style = "popin 82%" })
  hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "smooth" })
  hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "quick" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smooth", style = "fade" })
  hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "linear" })
end

return M
