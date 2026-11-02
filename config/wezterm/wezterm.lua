---@type Wezterm
local wezterm = require("wezterm")
local config = wezterm.config_builder()
wezterm.log_info("reloading")

require("tabs").setup(config)
require("mouse").setup(config)
require("keys").setup(config)
wezterm.plugin.require("https://github.com/smart-splits-nvim/backend-wezterm").apply_to_config(config, {
  direction_keys = {
    move = { "n", "e", "i", "o" },
    resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
  },
  modifiers = { move = "CTRL", resize = "CTRL" },
  at_edge = "stop",
})
require("links").setup(config)
require("theme").setup(config)

--- setting

-- config.front_end = "WebGpu"
-- config.front_end = "OpenGL" -- current work-around for https://github.com/wez/wezterm/issues/4825
config.enable_wayland = true
config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.underline_thickness = 3
config.cursor_thickness = 4
config.underline_position = -6

-- -- opacity
config.window_background_opacity = 0.85
-- config.term = "wezterm"
-- config.window_decorations = "RESIZE"
-- config.window_close_confirmation = "AlwaysPrompt"
-- config.scrollback_lines = 3000
-- config.default_workspace = "home"

-- enabled IME
-- config.use_ime = true
-- config.xim_im_name = "fcitx"

if wezterm.target_triple:find("windows") then
  config.default_prog = { "pwsh" }
  config.window_decorations = "RESIZE|TITLE"
  wezterm.on("gui-startup", function(cmd)
    local screen = wezterm.gui.screens().active
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    local gui = window:gui_window()
    local width = 0.7 * screen.width
    local height = 0.7 * screen.height
    gui:set_inner_size(width, height)
    gui:set_position((screen.width - width) / 2, (screen.height - height) / 2)
  end)
else
  config.term = "wezterm"
  config.window_decorations = "NONE"
end

-- colorschemes
-- config.color_scheme = "Tokyo Night Moon"
-- config.color_scheme_dirs = { wezterm.config_dir .. "/wezterm/themes" }
-- local colorscheme = os.getenv("MY_THEME")
-- config.color_scheme = colorscheme
-- wezterm.add_to_config_reload_watch_list(config.color_scheme_dirs[1] .. config.color_scheme .. ".toml")

--- font
config.font_size = 11
-- config.font = wezterm.font({ family = "JetBrainsMono Nerd Font" })
config.font = wezterm.font({ family = "CaskaydiaCove Nerd Font Mono" })
config.bold_brightens_ansi_colors = true
config.font_rules = {
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font({ family = "Maple Mono", weight = "Bold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Half",
    font = wezterm.font({ family = "Maple Mono", weight = "DemiBold", style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Normal",
    font = wezterm.font({ family = "Maple Mono", style = "Italic" }),
  },
}

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.force_reverse_video_cursor = true
config.window_padding = { left = 50, right = 50, top = 50, bottom = 50 }
-- window_background_opacity = 0.9,
-- cell_width = 0.9,
config.scrollback_lines = 10000

config.command_palette_font_size = 13
return config --[[@as Wezterm]]
