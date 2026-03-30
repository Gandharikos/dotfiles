local flavor = os.getenv("COLORSCHEME_FLAVOR") or "mocha"

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    optional = true,
    opts = {
      flavour = flavor,
      transparent_background = true,
    },
  },
}
