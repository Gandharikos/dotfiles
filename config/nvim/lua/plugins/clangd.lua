local function ensure(tbl, ...)
  for _, key in ipairs({ ... }) do
    tbl[key] = tbl[key] or {}
    tbl = tbl[key]
  end
  return tbl
end

return {
  -- correctly setup lspconfig
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local clangd = ensure(opts, "servers", "clangd")
      clangd.cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
      }

      local keys = clangd.keys or {}
      keys[#keys + 1] = {
        "s<space>",
        function()
          require("util.cpp").switch_source_header()
        end,
        desc = "Switch Source/Header (C/C++)",
      }
      clangd.keys = keys
    end,
  },
}
