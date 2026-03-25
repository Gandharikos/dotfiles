return {
  {
    "folke/flash.nvim",
    optional = true,
    opts = {
      search = { enabled = false },
      labels = "arstgmneioqwfpbjluyxcdvzkh",
      modes = {
        treesitter_search = {
          label = {
            rainbow = { enabled = true },
          },
        },
      },
    },
    keys = function(_, keys)
      keys[#keys + 1] = { "s", mode = { "n", "x", "o" }, false }
      keys[#keys + 1] = { "S", mode = { "n", "x", "o" }, false }
      keys[#keys + 1] = {
        "<cr>",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      }
      keys[#keys + 1] = {
        "<S-cr>",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      }
      for _, key in ipairs({ "f", "F", "t", "T", ";", ":", "/", "?" }) do
        table.insert(keys, key)
      end
      table.insert(keys, {
        "g<cr>",
        function()
          local Flash = require("flash")
          Flash.jump({
            search = { mode = "search" },
            label = { after = false, before = { 0, 0 }, uppercase = false },
            pattern = [[\<\|\>]],
            action = function(match, state)
              state:hide()
              Flash.jump({
                search = { max_length = 0 },
                label = { distance = false },
                highlight = { matches = false },
                matcher = function(win)
                  return vim.tbl_filter(function(m)
                    return m.label == match.label and m.win == win
                  end, state.results)
                end,
              })
            end,
            labeler = function(matches, state)
              local labels = state:labels()
              for m, match in ipairs(matches) do
                match.label = labels[math.floor((m - 1) / #labels) + 1]
              end
            end,
          })
        end,
        mode = { "n", "o", "x" },
        desc = "2-char jump",
      })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      preset = "helix",
      plugins = {
        marks = true,
        registers = true,
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = true,
          g = true,
        },
      },
      triggers = {
        { "<auto>", mode = "nixsotc" },
        { "s", mode = { "n", "x" } },
      },
    },
  },
  {
    "folke/trouble.nvim",
    optional = true,
    opts = {
      focus = true,
      modes = {
        cascade = {
          mode = "diagnostics", -- inherit from diagnostics mode
          focus = true,
          filter = function(items)
            local severity = vim.diagnostic.severity.HINT
            for _, item in ipairs(items) do
              severity = math.min(severity, item.severity)
            end
            return vim.tbl_filter(function(item)
              return item.severity == severity
            end, items)
          end,
        },
      },
    },
  },
  {
    "nvim-mini/mini.align",
    opts = {},
    keys = {
      { "ga", mode = { "n", "v" } },
      { "gA", mode = { "n", "v" } },
    },
  },
  {
    "nvim-mini/mini.operators",
    event = "BufRead",
    keys = {
      { "<M-t>", "sxiww.", desc = "transpose word after", remap = true, silent = true },
      { "<M-S-t>", "sxiwb.", desc = "transpose word before", remap = true, silent = true },
      { "<M-m>", "gmm", desc = "multiply line", remap = true, silent = true },
      { "<M-r>", "sciw", desc = "replace word", remap = true, silent = true },
    },
    opts = {
      exchange = {
        prefix = "sx",
      },
      replace = {
        prefix = "sc",
      },
    },
  },
  {
    "nvim-mini/mini.bracketed",
    event = "BufReadPost",
    opts = {
      file = { suffix = "" },
      window = { suffix = "" },
      quickfix = { suffix = "" },
      yank = { suffix = "" },
      treesitter = { suffix = "n" },
    },
  },
  {
    "Wansmer/treesj",
    keys = { { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" } },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },
  {
    "mrjones2014/smart-splits.nvim",
    build = "./kitty/install-kittens.bash",
    lazy = false,
    keys = {
      { "<leader>wr", "<Cmd>SmartResizeMode<CR>", mode = "n", desc = "Resize mode" },
      -- resizing splits
      {
        mode = { "n", "t" },
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "resize left",
      },
      {
        mode = { "n", "t" },
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "resize down",
      },
      {
        mode = { "n", "t" },
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "resize up",
      },
      {
        mode = { "n", "t" },
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "resize right",
      },
      -- moving between splits
      {
        mode = { "n", "t" },
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "move cursor left",
      },
      {
        mode = { "n", "t" },
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "move cursor down",
      },
      {
        mode = { "n", "t" },
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "move cursor up",
      },
      {
        mode = { "n", "t" },
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "move cursor right",
      },
      -- swapping buffers between windows
      {
        mode = { "n", "t" },
        "sH",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "swap buffer left",
      },
      {
        mode = { "n", "t" },
        "sJ",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "swap buffer down",
      },
      {
        mode = { "n", "t" },
        "sK",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "swap buffer up",
      },
      {
        mode = { "n", "t" },
        "sL",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "swap buffer right",
      },
    },
    opts = {
      ignored_filetypes = {
        "nofile",
        "quickfix",
        "prompt",
        "qf",
      },
      ignored_buftypes = { "NvimTree", "neo-tree" },
      default_amount = 3,
      move_cursor_same_row = false,
      resize_mode = {
        quit_key = "<ESC>",
        resize_keys = { "h", "j", "k", "l" },
        silent = false,
        hooks = {
          on_enter = function()
            vim.notify("Entering resize mode")
          end,
          on_leave = function()
            vim.notify("Exiting resize mode, bye")
          end,
        },
      },
      ignored_events = {
        "BufEnter",
        "WinEnter",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    keys = {
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "current file history" },
      { "<leader>go", "<cmd>DiffviewOpen<cr>", desc = "diffview open" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "diffview close" },
      { "<leader>gt", "<cmd>DiffviewToggleFiles<cr>", desc = "toggle files" },
      { "<leader>gh", "<cmd>'<,'>DiffviewFileHistory<cr>", desc = "file history", mode = "v" },
    },
    cmd = {
      "DiffviewFileHistory",
      "DiffviewFileHistory",
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFileHistory",
    },
    config = true,
  },
  -- git blame
  {
    "f-person/git-blame.nvim",
    event = "BufReadPre",
    opts = function()
      vim.g.gitblame_date_format = "%r"
    end,
    keys = {
      { "<leader>ug", "<CMD>GitBlameToggle<CR>", desc = "Toggle GitBlame" },
    },
  },

  -- git conflict
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    opts = {},
  },

  {
    "mbbill/undotree",
    lazy = true,
    cmd = "UndotreeToggle",
  },
  {
    "nvim-mini/mini.files",
    optional = true,
    keys = {
      { "sm", "<leader>fm", desc = "Mini-files (directory of current file)", remap = true },
      { "sM", "<leader>fM", desc = "Mini-files (cwd)", remap = true },
    },
  },
  {
    "nvim-mini/mini.move",
    optional = true,
    version = false,
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local opts = LazyVim.opts("mini.move")
      local mappings = {
        { opts.mappings.left, mode = "x" },
        { opts.mappings.right, mode = "x" },
        { opts.mappings.down, mode = "x" },
        { opts.mappings.up, mode = "x" },
        { opts.mappings.line_left },
        { opts.mappings.line_right },
        { opts.mappings.line_down },
        { opts.mappings.line_up },
      }
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = "<Left>",
        right = "<Right>",
        down = "<Down>",
        up = "<Up>",
        -- Move current line in Normal mode
        line_left = "<Left>",
        line_right = "<Right>",
        line_down = "<Down>",
        line_up = "<Up>",
      },
    },
  },
  {
    "monaqa/dial.nvim",
    optional = true,
    keys = function(_, keys)
      local map = { ["<C-a>"] = "+", ["<C-x>"] = "-", ["g<C-a>"] = "g+", ["g<C-x>"] = "g-" }
      for _, k in ipairs(keys) do
        k[1] = map[k[1]] or k[1]
      end
    end,
  },
}
