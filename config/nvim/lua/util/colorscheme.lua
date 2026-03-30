local M = {}

function M.transparent_lualine(theme_name)
  return {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local theme = require("lualine.themes." .. theme_name)
      theme.normal.c.bg = "none"
      opts.options.theme = theme
    end,
  }
end

return M
