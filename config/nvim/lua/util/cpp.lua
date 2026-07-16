local M = {}

local counterparts = {
  c = { "h" },
  cc = { "hh", "hpp", "h" },
  cpp = { "hpp", "h", "hxx" },
  cxx = { "hxx", "hpp", "h" },
  h = { "cpp", "cc", "cxx", "c" },
  hh = { "cc", "cpp", "cxx" },
  hpp = { "cpp", "cc", "cxx" },
  hxx = { "cxx", "cpp", "cc" },
}

local header_extensions = {
  h = true,
  hh = true,
  hpp = true,
  hxx = true,
}

local class_symbol_kinds = {
  [vim.lsp.protocol.SymbolKind.Class] = true,
  [vim.lsp.protocol.SymbolKind.Struct] = true,
}

local function_symbol_kinds = {
  [vim.lsp.protocol.SymbolKind.Constructor] = true,
  [vim.lsp.protocol.SymbolKind.Function] = true,
  [vim.lsp.protocol.SymbolKind.Method] = true,
  [vim.lsp.protocol.SymbolKind.Operator] = true,
}

local function project_root(path)
  return vim.fs.root(path, { "compile_commands.json", "CMakeLists.txt", ".git" }) or vim.fs.dirname(path)
end

local function find_counterpart(path)
  local extension = vim.fn.fnamemodify(path, ":e")
  local target_extensions = counterparts[extension]
  if not target_extensions then
    return nil
  end

  local root = project_root(path)
  local basename = vim.fn.fnamemodify(path, ":t:r")
  local preferred_directory = header_extensions[extension] and "src" or "include"
  local search_paths = {
    root .. "/" .. preferred_directory,
    vim.fs.dirname(path),
    root,
  }

  for _, target_extension in ipairs(target_extensions) do
    local target_name = basename .. "." .. target_extension
    for _, search_path in ipairs(search_paths) do
      if vim.uv.fs_stat(search_path) then
        local match = vim.fs.find(target_name, {
          path = search_path,
          type = "file",
          limit = 1,
        })[1]
        if match then
          return match
        end
      end
    end
  end
end

local function position_is_before_or_equal(left, right)
  return left.line < right.line or (left.line == right.line and left.character <= right.character)
end

local function range_contains(range, position)
  return position_is_before_or_equal(range.start, position) and position_is_before_or_equal(position, range["end"])
end

local function symbol_at(symbols, position, namespaces)
  namespaces = namespaces or {}
  for _, symbol in ipairs(symbols or {}) do
    if symbol.range and range_contains(symbol.range, position) then
      local child_namespaces = vim.deepcopy(namespaces)
      if symbol.kind == vim.lsp.protocol.SymbolKind.Namespace then
        table.insert(child_namespaces, symbol.name)
      end
      local nested_symbol, nested_namespaces = symbol_at(symbol.children, position, child_namespaces)
      if nested_symbol then
        return nested_symbol, nested_namespaces
      end
      return symbol, child_namespaces
    end
  end
end

local function clangd_client(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/documentSymbol" })) do
    if client.name == "clangd" and client:supports_method("textDocument/definition", bufnr) then
      return client
    end
  end
end

local function has_definition(locations, declaration_uri, declaration_position)
  if not locations then
    return false
  end

  local definition_locations = (locations.uri or locations.targetUri) and { locations } or locations
  for _, location in ipairs(definition_locations) do
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange
    if uri ~= declaration_uri then
      return true
    end
    if
      range
      and (range.start.line ~= declaration_position.line or range.start.character ~= declaration_position.character)
    then
      return true
    end
  end
  return false
end

local function include_name(header, root)
  local include_prefix = root .. "/include/"
  if header:sub(1, #include_prefix) == include_prefix then
    return header:sub(#include_prefix + 1)
  end
  return vim.fs.basename(header)
end

local function source_path_for(header)
  local existing_source = find_counterpart(header)
  if existing_source then
    return existing_source
  end

  local root = project_root(header)
  local source_directory = vim.uv.fs_stat(root .. "/src") and root .. "/src" or vim.fs.dirname(header)
  return source_directory .. "/" .. vim.fn.fnamemodify(header, ":t:r") .. ".cpp"
end

local function append_definitions(header, definitions, namespaces)
  local source = source_path_for(header)
  local source_existed = vim.uv.fs_stat(source) ~= nil
  vim.api.nvim_cmd({ cmd = "edit", args = { source } }, {})

  local bufnr = vim.api.nvim_get_current_buf()
  if not source_existed then
    local root = project_root(header)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      ('#include "%s"'):format(include_name(header, root)),
      "",
    })
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local insertion_line = #lines + 1
  local new_lines = {}
  if #lines > 0 and lines[#lines] ~= "" then
    table.insert(new_lines, "")
    insertion_line = insertion_line + 1
  end
  local definition_block = table.concat(definitions, "\n\n")
  if #namespaces > 0 then
    local namespace = table.concat(namespaces, "::")
    definition_block = ("namespace %s {\n\n%s\n\n} // namespace %s"):format(namespace, definition_block, namespace)
  end
  vim.list_extend(new_lines, vim.split(vim.trim(definition_block), "\n", { plain = true }))
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, new_lines)
  vim.api.nvim_win_set_cursor(0, { insertion_line, 0 })

  vim.notify(("Created %d out-of-line definition%s"):format(#definitions, #definitions == 1 and "" or "s"))
end

local function generate_definitions(bufnr, header, members, namespaces)
  table.sort(members, function(left, right)
    local left_position = left.selectionRange.start
    local right_position = right.selectionRange.start
    return left_position.line < right_position.line
      or (left_position.line == right_position.line and left_position.character < right_position.character)
  end)

  local definitions = {}
  vim.api.nvim_buf_call(bufnr, function()
    local cpp_tools = require("nt-cpp-tools.internal")
    for _, member in ipairs(members) do
      cpp_tools.imp_func(member.range.start.line + 1, member.range["end"].line + 1, function(output)
        table.insert(definitions, vim.trim(output))
      end)
    end
  end)

  if #definitions == 0 then
    vim.notify("No member declarations can be implemented here", vim.log.levels.INFO)
    return
  end
  append_definitions(header, definitions, namespaces)
end

local function generate_missing_definitions(client, bufnr, header, members, namespaces)
  if #members == 0 then
    vim.notify("The class has no member functions", vim.log.levels.INFO)
    return
  end

  local pending = #members
  local missing = {}
  local request_failed = false
  local text_document = vim.lsp.util.make_text_document_params(bufnr)

  for _, member in ipairs(members) do
    local position = member.selectionRange.start
    client:request("textDocument/definition", {
      textDocument = text_document,
      position = position,
    }, function(error, locations)
      if error then
        request_failed = true
      elseif not has_definition(locations, text_document.uri, position) then
        table.insert(missing, member)
      end

      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          if request_failed then
            vim.notify("clangd could not verify every existing definition", vim.log.levels.WARN)
          end
          if #missing == 0 then
            vim.notify("All selected functions already have definitions", vim.log.levels.INFO)
            return
          end
          generate_definitions(bufnr, header, missing, namespaces)
        end)
      end
    end, bufnr)
  end
end

function M.implement_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local header = vim.api.nvim_buf_get_name(bufnr)
  if not header_extensions[vim.fn.fnamemodify(header, ":e")] then
    vim.notify("Place the cursor in a C++ header", vim.log.levels.WARN)
    return
  end

  -- A .h file is ambiguous; invoking this C++ action makes the intended language explicit.
  if vim.bo[bufnr].filetype == "c" then
    vim.bo[bufnr].filetype = "cpp"
  end

  local client = clangd_client(bufnr)
  if not client then
    vim.notify("clangd is not ready for this header", vim.log.levels.WARN)
    return
  end

  local cursor = vim.lsp.util.make_position_params(0, client.offset_encoding).position
  client:request(
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params(bufnr) },
    function(error, symbols)
      if error then
        vim.notify("clangd could not inspect this header", vim.log.levels.ERROR)
        return
      end

      local symbol, namespaces = symbol_at(symbols, cursor)
      local members = {}
      if symbol and function_symbol_kinds[symbol.kind] then
        members = { symbol }
      elseif symbol and class_symbol_kinds[symbol.kind] then
        for _, child in ipairs(symbol.children or {}) do
          if function_symbol_kinds[child.kind] then
            table.insert(members, child)
          end
        end
      else
        vim.notify("Place the cursor on a function, class, or struct", vim.log.levels.WARN)
        return
      end

      generate_missing_definitions(client, bufnr, header, members, namespaces)
    end,
    bufnr
  )
end

function M.switch_source_header()
  local target = find_counterpart(vim.api.nvim_buf_get_name(0))
  if not target then
    vim.notify("No matching C/C++ source or header file found", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_cmd({ cmd = "edit", args = { target } }, {})
end

return M
