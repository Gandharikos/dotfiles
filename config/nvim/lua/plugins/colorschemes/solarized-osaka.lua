local variant = os.getenv("COLORSCHEME_VARIANT") or "dark"
local transparent = os.getenv("COLORSCHEME_TRANSPARENT") == "true"

return {
  {
    "craftzdog/solarized-osaka.nvim",
    init = function()
      vim.o.background = variant == "light" and "light" or "dark"
    end,
    opts = {
      style = variant == "dark" and "" or variant,
      transparent = transparent,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "solarized-osaka",
    },
  },
}
