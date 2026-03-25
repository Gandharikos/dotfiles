return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    ft = { "markdown", "vimwiki", "norg", "rmd", "org" },
    opts = function()
      return {
        file_types = { "markdown", "norg", "rmd", "org" },
      }
    end,
  },
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      image = {},
    },
  },
  {
    "zk-org/zk-nvim",
    ft = "markdown",
    config = function()
      require("zk").setup({
        picker = "snacks_picker",
        lsp = {
          -- `config` is passed to `vim.lsp.start_client(config)`
          config = {
            cmd = { "zk", "lsp" },
            name = "zk",
          },
          -- automatically attach buffers in a zk notebook that match the given filetypes
          auto_attach = {
            enabled = true,
            filetypes = { "markdown" },
          },
        },
      })
    end,
    cmd = { "ZkNotes", "ZkNew", "ZkIndex" },
    keys = {
      { "<leader>zn", [[:ZkNew {title=''}<left><left>]], mode = "n" },
      { "<leader>zn", [[<cmd>ZkNewFromTitleSelection<cr>]], mode = "x" },
      { "<leader>zl", [[<cmd>ZkNotes<cr>]] },
      { "<leader>zt", [[<cmd>ZkTags<cr>]] },
    },
  },
}
