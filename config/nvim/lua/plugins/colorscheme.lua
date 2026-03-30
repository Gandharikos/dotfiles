local M = {}

local colorscheme_name = os.getenv("COLORSCHEME_NAME") or "tokyonight"
local theme_path = "plugins.colorschemes." .. colorscheme_name
local has_theme, _ = pcall(require, theme_path)

if not has_theme then
  colorscheme_name = "tokyonight"
  theme_path = "plugins.colorschemes." .. colorscheme_name
end

M = {
  { import = theme_path },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme_name,
    },
  },
}

return M
