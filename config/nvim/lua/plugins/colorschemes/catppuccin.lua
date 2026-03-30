local colorscheme = require("util.colorscheme")

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    optional = true,
    opts = function(_, opts)
      local old_custom_highlights = opts.custom_highlights

      opts.transparent_background = true
      opts.float = vim.tbl_deep_extend("force", opts.float or {}, {
        transparent = true,
        solid = false,
      })
      opts.custom_highlights = function(colors)
        local highlights = {}
        if old_custom_highlights then
          highlights = old_custom_highlights(colors) or {}
        end

        highlights.StatusLine = { bg = "none" }
        highlights.WinBar = { bg = "none" }
        highlights.NormalFloat = { bg = "none" }

        return highlights
      end
    end,
  },
  colorscheme.transparent_lualine("catppuccin-nvim"),
}
