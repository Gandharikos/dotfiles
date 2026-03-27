local layout = require("util.layout")

if not layout.is_colemak() then
  return {}
end

local function replace_keys(keys, defs)
  for _, def in ipairs(defs) do
    local lhs = def[1]
    for idx = #keys, 1, -1 do
      if keys[idx][1] == lhs then
        table.remove(keys, idx)
      end
    end
    table.insert(keys, def)
  end
  return keys
end

local function ensure(tbl, ...)
  for _, key in ipairs({ ... }) do
    tbl[key] = tbl[key] or {}
    tbl = tbl[key]
  end
  return tbl
end

return {
  {
    "nvim-mini/mini.ai",
    optional = true,
    keys = {
      { "a", mode = { "x", "o" } },
      { "h", mode = { "x", "o" } },
    },
    opts = {
      n_lines = 500,
      custom_textobjects = {
        w = { "()()%f[%w]%w+()[ \t]*()" },
      },
      mappings = {
        inside = "h",
        inside_next = "hn",
        inside_last = "hl",
      },
    },
  },
  {
    "folke/snacks.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local picker = ensure(opts, "picker")
      local explorer_keys = ensure(picker, "sources", "explorer", "win", "list", "keys")
      explorer_keys.h = "focus_input"
      explorer_keys.n = "explorer_close"
      explorer_keys.o = "confirm"
      explorer_keys.l = "explorer_open"
      explorer_keys.s = "edit_split"
      explorer_keys.v = "edit_vsplit"

      local input_keys = ensure(picker, "win", "input", "keys")
      input_keys["<c-e>"] = { "list_down", mode = { "i", "n" } }
      input_keys["<c-i>"] = { "list_up", mode = { "i", "n" } }
      input_keys.e = "list_down"
      input_keys.i = "list_up"
      input_keys["<c-w>N"] = "layout_left"
      input_keys["<c-w>E"] = "layout_bottom"
      input_keys["<c-w>I"] = "layout_top"
      input_keys["<c-w>O"] = "layout_right"

      local list_keys = ensure(picker, "win", "list", "keys")
      list_keys["<c-e>"] = "list_down"
      list_keys["<c-i>"] = "list_up"
      list_keys["<c-w>N"] = "layout_left"
      list_keys["<c-w>E"] = "layout_bottom"
      list_keys["<c-w>I"] = "layout_top"
      list_keys["<c-w>O"] = "layout_right"
      list_keys.h = "focus_input"
      list_keys.e = "list_down"
      list_keys.i = "list_up"

      return opts
    end,
  },
  {
    "folke/trouble.nvim",
    optional = true,
    opts = function(_, opts)
      opts.keys = vim.tbl_extend("force", opts.keys or {}, {
        I = "inspect",
        e = "next",
        i = "prev",
      })
      return opts
    end,
  },
  {
    "nvim-mini/mini.operators",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "<M-t>", "sxhww.", desc = "transpose word after", remap = true, silent = true },
        { "<M-S-t>", "sxhwb.", desc = "transpose word before", remap = true, silent = true },
        { "<M-r>", "schw", desc = "replace word", remap = true, silent = true },
      })
    end,
  },
  {
    "Wansmer/treesj",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "E", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
      })
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        -- resizing splits
        {
          mode = { "n", "t" },
          "<A-n>",
          function()
            require("smart-splits").resize_left()
          end,
          desc = "resize left",
        },
        {
          mode = { "n", "t" },
          "<A-e>",
          function()
            require("smart-splits").resize_down()
          end,
          desc = "resize down",
        },
        {
          mode = { "n", "t" },
          "<A-i>",
          function()
            require("smart-splits").resize_up()
          end,
          desc = "resize up",
        },
        {
          mode = { "n", "t" },
          "<A-o>",
          function()
            require("smart-splits").resize_right()
          end,
          desc = "resize right",
        },
        {
          "<C-n>",
          function()
            require("smart-splits").move_cursor_left()
          end,
          desc = "move cursor left",
          mode = { "n", "t" },
        },
        {
          "<C-e>",
          function()
            require("smart-splits").move_cursor_down()
          end,
          desc = "move cursor down",
          mode = { "n", "t" },
        },
        {
          "<C-i>",
          function()
            require("smart-splits").move_cursor_up()
          end,
          desc = "move cursor up",
          mode = { "n", "t" },
        },
        {
          "<C-o>",
          function()
            require("smart-splits").move_cursor_right()
          end,
          desc = "move cursor right",
          mode = { "n", "t" },
        },
        {
          "sN",
          function()
            require("smart-splits").swap_buf_left()
          end,
          desc = "swap buffer left",
          mode = { "n", "t" },
        },
        {
          "sE",
          function()
            require("smart-splits").swap_buf_down()
          end,
          desc = "swap buffer down",
          mode = { "n", "t" },
        },
        {
          "sI",
          function()
            require("smart-splits").swap_buf_up()
          end,
          desc = "swap buffer up",
          mode = { "n", "t" },
        },
        {
          "sO",
          function()
            require("smart-splits").swap_buf_right()
          end,
          desc = "swap buffer right",
          mode = { "n", "t" },
        },
      })
    end,
    opts = function(_, opts)
      opts = opts or {}
      opts.resize_mode = opts.resize_mode or {}
      opts.resize_mode.resize_keys = { "n", "e", "i", "o" }
      return opts
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    optional = true,
    opts = function(_, opts)
      local prev_attach = opts.on_attach
      opts.on_attach = function(buffer)
        if prev_attach then
          prev_attach(buffer)
        end
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
        end
        local function unmap(mode, lhs)
          vim.keymap.del(mode, lhs, { buffer = buffer })
        end
        unmap({ "o", "x" }, "ih")
        map({ "o", "x" }, "hh", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end
      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local server = ensure(opts, "servers", "*")
      server.keys = replace_keys(server.keys or {}, {
        { "K", false },
        { "gK", false },
        { "<c-k>", false, mode = "i" },
        { "<a-n>", false },
        { "<a-p>", false },
        { "I", vim.lsp.buf.hover, desc = "Hover" },
        { "gI", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
        {
          "<c-h>",
          vim.lsp.buf.signature_help,
          mode = "i",
          desc = "Signature Help",
          has = "signatureHelp",
        },
        {
          "<a-.>",
          function()
            Snacks.words.jump(vim.v.count1, true)
          end,
          has = "documentHighlight",
          desc = "Next Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
        {
          "<a-,>",
          function()
            Snacks.words.jump(-vim.v.count1, true)
          end,
          has = "documentHighlight",
          desc = "Prev Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
      })
      return opts
    end,
  },
  -- Extras overrides
  {
    "nvim-mini/mini.splitjoin",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = vim.tbl_extend("force", opts.mappings or {}, { toggle = "E" })
      return opts
    end,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "E", desc = "Split/Join" },
      })
    end,
  },
  {
    "nvim-mini/mini.surround",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
        update_n_lines = "sl",
      })
      return opts
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = vim.tbl_deep_extend("force", opts.mapping or {}, {
        ["<C-e>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-i>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      })
      -- remove qwerty mappings if present
      opts.mapping["<C-j>"] = nil
      opts.mapping["<C-k>"] = nil
      return opts
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "<leader>dj", false },
        { "<leader>dk", false },
        { "<leader>dB", false },
        {
          "<leader>db",
          function()
            require("dap").step_back()
          end,
          desc = "Step back",
        },
        {
          "<leader>de",
          function()
            require("dap").down()
          end,
          desc = "Down",
        },
        {
          "<leader>di",
          function()
            require("dap").up()
          end,
          desc = "Up",
        },
        {
          "<leader>dI",
          function()
            require("dap").step_into()
          end,
          desc = "Step Into",
        },
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "<leader>de", false, mode = { "n", "v" } },
        {
          "<leader>dE",
          function()
            require("dapui").eval()
          end,
          desc = "Eval",
          mode = { "n", "v" },
        },
      })
    end,
  },
  {
    "ibhagwan/fzf-lua",
    optional = true,
    keys = function(_, keys)
      return replace_keys(keys, {
        { "<c-j>", false },
        { "<c-k>", false },
        { "<c-e>", "<Down>", ft = "fzf", mode = "t", nowait = true },
        { "<c-i>", "<Up>", ft = "fzf", mode = "t", nowait = true },
      })
    end,
  },
  {
    "nvim-mini/mini.files",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
        go_in = "o",
        go_in_plus = "O",
        go_out = "n",
        go_out_plus = "N",
      })
      return opts
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local filesystem = ensure(opts, "filesystem")
      filesystem.window = filesystem.window or {}
      filesystem.window.mappings = vim.tbl_extend("force", filesystem.window.mappings or {}, {
        h = "none",
        l = "none",
        n = "close_node",
        o = "open",
        O = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "O" } },
        Oc = { "order_by_created", nowait = false },
        Od = { "order_by_diagnostics", nowait = false },
        Og = { "order_by_git_status", nowait = false },
        Om = { "order_by_modified", nowait = false },
        On = { "order_by_name", nowait = false },
        Os = { "order_by_size", nowait = false },
        Ot = { "order_by_type", nowait = false },
        oc = "none",
        od = "none",
        og = "none",
        om = "none",
        on = "none",
        os = "none",
        ot = "none",
      })

      local buffers = ensure(opts, "buffers", "window", "mappings")
      buffers.O = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "O" } }
      buffers.Oc = { "order_by_created", nowait = false }
      buffers.Od = { "order_by_diagnostics", nowait = false }
      buffers.Om = { "order_by_modified", nowait = false }
      buffers.On = { "order_by_name", nowait = false }
      buffers.Os = { "order_by_size", nowait = false }
      buffers.Ot = { "order_by_type", nowait = false }
      buffers.o = "none"
      buffers.oc = "none"
      buffers.od = "none"
      buffers.om = "none"
      buffers.on = "none"
      buffers.os = "none"
      buffers.ot = "none"

      local git_status = ensure(opts, "git_status", "window", "mappings")
      git_status.O = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "O" } }
      git_status.Oc = { "order_by_created", nowait = false }
      git_status.Od = { "order_by_diagnostics", nowait = false }
      git_status.Om = { "order_by_modified", nowait = false }
      git_status.On = { "order_by_name", nowait = false }
      git_status.Os = { "order_by_size", nowait = false }
      git_status.Ot = { "order_by_type", nowait = false }
      git_status.o = "none"
      git_status.oc = "none"
      git_status.od = "none"
      git_status.om = "none"
      git_status.on = "none"
      git_status.os = "none"
      git_status.ot = "none"

      local win = ensure(opts, "window", "mappings")
      win.e = "none"
      win.E = "toggle_auto_expand_width"
      win.N = { "toggle_node", nowait = false }
      win.I = "show_file_details"
      win.i = "none"
      return opts
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.defaults = opts.defaults or {}
      opts.defaults.mappings = opts.defaults.mappings or {}
      local insert = ensure(opts.defaults.mappings, "i")
      insert["<C-e>"] = function(...)
        return require("telescope.actions").move_selection_next(...)
      end
      insert["<C-i>"] = function(...)
        return require("telescope.actions").move_selection_previous(...)
      end
      insert["<C-h>"] = function(...)
        return require("telescope.actions").select_horizontal(...)
      end
      insert["<C-s>"] = function(...)
        return require("telescope.actions").select_tab(...)
      end

      local normal = ensure(opts.defaults.mappings, "n")
      normal.e = function(...)
        return require("telescope.actions").move_selection_next(...)
      end
      normal.i = function(...)
        return require("telescope.actions").move_selection_previous(...)
      end
      normal.j = nil
      normal.k = nil
      normal.h = function(...)
        return require("telescope.actions").select_horizontal(...)
      end
      normal.s = function(...)
        return require("telescope.actions").select_tab(...)
      end
      return opts
    end,
  },
  {
    "nvim-mini/mini.indentscope",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = vim.tbl_extend("force", opts.mappings or {}, {
        object_scope = "hi",
      })
      return opts
    end,
  },
  {
    "sindrets/winshift.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.keymaps = {
        disable_defaults = true,
        win_move_mode = {
          n = "left",
          e = "down",
          i = "up",
          o = "right",
          N = "far_left",
          E = "far_down",
          I = "far_up",
          O = "far_right",
          ["<left>"] = "left",
          ["<down>"] = "down",
          ["<up>"] = "up",
          ["<right>"] = "right",
          ["<S-left>"] = "far_left",
          ["<S-down>"] = "far_down",
          ["<S-up>"] = "far_up",
          ["<S-right>"] = "far_right",
        },
      }
      return opts
    end,
  },
}
