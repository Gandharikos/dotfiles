local style = os.getenv("COLORSCHEME_STYLE") or "moon"

return {
  {
    "folke/tokyonight.nvim",
    optional = true,
    opts = {
      on_highlights = function(hl, _)
        hl.StatusLine = { bg = "none" } -- status line of current window
        hl.WinBar = { bg = "none" } -- window bar of current window
        hl.NormalFloat = { bg = "none" } -- set float windows background to transparent
      end,
      style = style,
      transparent = true, -- Enable this to disable setting the background color
    },
  },
}
