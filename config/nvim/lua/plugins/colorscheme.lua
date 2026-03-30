local M = {}

local colorscheme = os.getenv("THEME") or "tokyonight"
local theme_path = "plugins.colorschemes." .. colorscheme
local has_theme, _ = pcall(require, theme_path)

if not has_theme then
  colorscheme = "tokyonight"
  theme_path = "plugins.colorschemes." .. colorscheme
end

M = {
  { import = theme_path },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme,
    },
  },
}

return M
