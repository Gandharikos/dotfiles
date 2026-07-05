local M = {}

function M.setup(ctx)
  local theme = ctx.theme or {}

  for _, monitor in ipairs(ctx.monitors or {}) do
    hl.monitor(monitor)
  end
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

  hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
  hl.env("XDG_SESSION_DESKTOP", "Hyprland")
  hl.env("WLR_NO_HARDWARE_CURSORS", "1")

  hl.config({
    general = {
      border_size = 2,
      gaps_in = 4,
      gaps_out = 8,
      gaps_workspaces = 12,
      no_focus_fallback = false,
      resize_on_border = true,
      extend_border_grab_area = 10,
      hover_icon_on_border = true,
      resize_corner = 3,
      layout = "scrolling",
      snap = { enabled = true },
      ["col.active_border"] = theme.active_border,
      ["col.inactive_border"] = theme.inactive_border,
    },
    scrolling = {
      fullscreen_on_one_column = true,
      column_width = 0.5,
      focus_fit_method = 1,
      follow_focus = true,
      follow_min_visible = 0.4,
      explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
      wrap_focus = true,
      wrap_swapcol = true,
      direction = "right",
    },
    xwayland = {
      force_zero_scaling = true,
    },
    misc = {
      disable_hyprland_logo = true,
      disable_splash_rendering = true,
      mouse_move_enables_dpms = true,
      enable_swallow = false,
      swallow_regex = "^(org.wezfurlong.wezterm)$",
      vrr = 2,
      background_color = theme.background,
    },
    group = {
      ["col.border_active"] = theme.group_active,
      ["col.border_inactive"] = theme.group_inactive,
      ["col.border_locked_active"] = theme.group_locked_active,
      groupbar = {
        text_color = theme.group_text,
        ["col.active"] = theme.group_active,
        ["col.inactive"] = theme.group_inactive,
      },
    },
  })
end

return M
