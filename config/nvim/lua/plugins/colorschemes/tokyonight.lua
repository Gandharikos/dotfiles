local colorscheme = require("util.colorscheme")

return {
  {
    "folke/tokyonight.nvim",
    optional = true,
    opts = function(_, opts)
      local old_on_highlights = opts.on_highlights
      local style = os.getenv("COLORSCHEME_STYLE") or "moon"

      opts.style = style
      opts.transparent = true
      opts.on_highlights = function(hl, colors)
        if old_on_highlights then
          old_on_highlights(hl, colors)
        end

        hl.StatusLine = { bg = "none" }
        hl.WinBar = { bg = "none" }
        hl.NormalFloat = { bg = "none" }
      end
    end,
  },
  colorscheme.transparent_lualine("tokyonight"),
}
