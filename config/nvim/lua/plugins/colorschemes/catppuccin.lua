local flavor = os.getenv("COLORSCHEME_FLAVOR") or "mocha"

return {
  {
    "catppuccin",
    optional = true,
    opts = {
      flavour = flavor,
      transparent_background = true,
      float = {
        transparent = true, -- enable transparent floating windows
        solid = true, -- use solid styling for floating windows, see |winborder|
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-nvim",
    },
  },
}
