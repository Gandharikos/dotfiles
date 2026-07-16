return {
  {
    "Badhi/nvim-treesitter-cpp-tools",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      { "nvim-treesitter/nvim-treesitter-grammar-cpp", lazy = false },
    },
    ft = { "c", "cpp" },
    keys = {
      {
        "<leader>ci",
        function()
          require("util.cpp").implement_at_cursor()
        end,
        desc = "Implement Function/Class",
      },
    },
    opts = {
      header_extension = "hpp",
      source_extension = "cpp",
    },
  },
}
