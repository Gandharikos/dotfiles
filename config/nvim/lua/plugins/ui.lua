return {
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      scope = {
        enabled = false,
      },
      zen = {
        toggles = {
          dim = false,
          git_signs = false,
          mini_diff_signs = false,
        },
        win = {
          backdrop = { transparent = false, blend = 99 },
          wo = {
            number = false,
            relativenumber = false,
            colorcolumn = "",
            signcolumn = "no",
            statuscolumn = "",
            winbar = "",
            cursorline = false,
          },
        },
        on_open = function()
          -- disable snacks indent
          Snacks.indent.disable()
          -- hide tmux statusbar
          vim.fn.system("tmux set status off")
        end,
        on_close = function()
          -- restore snacks indent setting
          Snacks.indent.enable()
          -- restore tmux statusbar
          vim.fn.system("tmux set status on")
        end,
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    optional = true,
    cond = not vim.g.started_by_firenvim,
    dependencies = {
      {
        "tiagovla/scope.nvim",
        config = true,
      },
    },
    keys = {
      -- { "<Tab>", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
      -- { "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous" },
      { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Jump" },
      { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick Close" },
      { "<leader>b[", "<cmd>BufferLineMoveLeft<cr>", desc = "Move left" },
      { "<leader>b]", "<cmd>BufferLineMoveRight<cr>", desc = "Move right" },
      { "<leader>b{", "<cmd>BufferLineCloseLeft<cr>", desc = "Close all to the left" },
      { "<leader>b}", "<cmd>BufferLineCloseRight<cr>", desc = "Close all to the right" },
      { "<leader>bD", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
      { "<leader>bL", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by language" },
    },
    opts = {
      highlights = {
        background = {
          italic = true,
        },
        buffer_selected = {
          bold = true,
        },
      },
      options = {
        indicator = {
          style = "underline", -- can also be 'underline'|'none',
        },
        name_formatter = function(buf) -- buf contains a "name", "path" and "bufnr"
          -- remove extension from markdown files for example
          if buf.name:match("%.md") then
            return vim.fn.fnamemodify(buf.name, ":t:r")
          end
        end,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
      },
    },
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "v1.*",
    keys = {
      {
        "<leader>ww",
        function()
          local picker = require("window-picker")
          local picked_window_id = picker.pick_window({
            include_current_win = true,
          }) or vim.api.nvim_get_current_win()
          vim.api.nvim_set_current_win(picked_window_id)
        end,
        desc = "Pick a window",
      },
      { "sw", "<leader>ww", remap = true, desc = "Pick window" },
      {
        "<leader>wx",
        function()
          local picker = require("window-picker")
          local window = picker.pick_window({
            include_current_win = false,
          })
          local target_buffer = vim.fn.winbufnr(window)
          -- Set the target window to contain current buffer
          vim.api.nvim_win_set_buf(window, 0)
          -- Set current window to contain target buffer
          vim.api.nvim_win_set_buf(0, target_buffer)
        end,
        desc = "Exchange a window",
      },
      { "sW", "<leader>ws", remap = true, desc = "Swap window" },
    },
    opts = {
      autoselect_one = true,
      include_current = false,
      filter_rules = {
        -- filter using buffer options
        bo = {
          -- if the file type is one of following, the window will be ignored
          filetype = { "neo-tree", "neo-tree-popup", "notify", "NvimTree" },

          -- if the buffer type is one of following, the window will be ignored
          buftype = { "terminal", "quickfix" },
        },
      },
      other_win_hl_color = "#e35e4f",
      selection_chars = "ASTNEIOXFPLUDHKMCV",
    },
    config = function(_, opts)
      require("window-picker").setup(opts)
    end,
  },
  {
    "sindrets/winshift.nvim",
    cmd = "WinShift",
    opts = {
      highlight_moving_win = true,
    },
    keys = { { "<leader>ws", "<CMD>WinShift<CR>", desc = "Window Shift" } },
  },
}
