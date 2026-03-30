local M = {}

local colorscheme_name = os.getenv("COLORSCHEME_NAME") or "tokyonight"
local theme_path = "plugins.colorschemes." .. colorscheme_name

M = {
  { import = theme_path },
}

return M
