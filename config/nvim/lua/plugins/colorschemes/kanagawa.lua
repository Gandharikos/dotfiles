local variant = os.getenv("COLORSCHEME_VARIANT") or "wave"
local transparent = os.getenv("COLORSCHEME_TRANSPARENT") == "true"

return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      theme = variant,
      transparent = transparent,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-" .. variant,
    },
  },
}
