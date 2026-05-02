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
        "--fallback-style=file",
        "--header-insertion=iwyu",
      }

      local keys = clangd.keys or {}
      keys[#keys + 1] = { "s<space>", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" }
      clangd.keys = keys
    end,
  },
}
