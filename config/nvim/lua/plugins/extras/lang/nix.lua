return {
  { import = "lazyvim.plugins.extras.lang.nix" },
  {
    "stevaearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
    },
  },
}
