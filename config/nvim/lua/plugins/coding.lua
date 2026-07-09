return {
  {
    "folke/ts-comments.nvim",
    enabled = false,
  },
  {
    "nvim-mini/mini.pairs",
    optional = true,
    event = function()
      return { "InsertEnter" }
    end,
  },
  {
    "nvim-mini/mini.surround",
    optional = true,
    opts = {
      mappings = {
        add = "sa", -- Add surrounding in Normal and Visual modes
        delete = "sd", -- Delete surrounding
        find = "sf", -- Find surrounding (to the right)
        find_left = "sF", -- Find surrounding (to the left)
        highlight = "sh", -- Highlight surrounding
        replace = "sr", -- Replace surrounding
        update_n_lines = "sn", -- Update `n_lines`
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "s", group = "surround/select/split" },
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      keymap = {
        preset = "super-tab",
      },
    },
  },
}
