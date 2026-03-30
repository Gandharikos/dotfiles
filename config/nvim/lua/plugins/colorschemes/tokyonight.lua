local style = os.getenv("COLORSCHEME_STYLE") or "moon"

return {
  {
    "folke/tokyonight.nvim",
    optional = true,
    opts = {
      style = style,
      transparent = true, -- Enable this to disable setting the background color
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
