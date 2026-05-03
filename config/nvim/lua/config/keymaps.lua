local map = LazyVim.safe_keymap_set
-- Search visually selected text (slightly better than builtins in Neovim>=0.8)
map("x", "*", [[y/\V<C-R>=escape(@", '/\')<CR><CR>]])
map("x", "#", [[y?\V<C-R>=escape(@", '?\')<CR><CR>]])

-- select all
map({ "n", "x", "i" }, "<C-a>", "<cmd>normal! ggVG<cr>")

-- inc/dec number
map({ "n", "v" }, "+", "<C-a>", { desc = "Increment number" })
map({ "n", "v" }, "-", "<C-x>", { desc = "Decrement number" })
map({ "n", "v" }, "g+", "g<C-a>", { desc = "Increment number" })
map({ "n", "v" }, "g-", "g<C-x>", { desc = "Decrement number" })

-- emacs delete end of line
map("i", "<C-k>", "<cmd>normal! d$<cr>", { silent = true, desc = "delete to end of line" })

-- emacs kill a whole line
map("i", "<M-x>", "<cmd>normal! dd<cr>", { silent = true, desc = "kill the whole line" })

-- emacs delete next word
map("i", "<M-d>", "<cmd>normal! dw<cr>", { silent = true, desc = "delete next word" })

-- emacs forward/backward word
map("i", "<M-f>", "<C-Right>", { silent = true, desc = "forward word" })
map("i", "<M-b>", "<C-Left>", { silent = true, desc = "backward word" })

-- emacs begin/end of line
-- map("i", "<C-a>", "<Home>", { silent = true, desc = "begin of line" })
-- map("i", "<C-e>", "<End>", { silent = true, desc = "end of line" })

-- autocorrect spelling from previous error
-- map("i", "<C-f>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { expr = true, silent = true })

-- paste
map("i", "<C-v>", "<C-g>u<Cmd>set paste<CR><C-r>+<Cmd>set nopaste<CR>")
map("t", "<C-v>", "<C-\\><C-N>pi")
map("c", "<C-v>", "<C-r>+")

-- insert mode navigation
-- map("i", "<A-Up>", "<C-\\><C-N><C-w>k")
-- map("i", "<A-Down>", "<C-\\><C-N><C-w>j")
-- map("i", "<A-Left>", "<C-\\><C-N><C-w>h")
-- map("i", "<A-Right>", "<C-\\><C-N><C-w>l")

-- Terminal window navigation
--WARN: <esc><esc> is not work when timeoutlen=0
map("t", "<C-esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
map("t", "<C-q>", "<cmd>close<cr>", { desc = "Hide Terminal" })
-- map("n", "<C-cr>", function()
--   LazyVim.terminal(nil, { ft = "", border = "rounded" })
-- end, { desc = "Float Terminal" })
-- map("t", "<C-cr>", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- btop
map("n", "<leader>xb", function()
  Snacks.terminal({ "btop" }, { esc_esc = false, ctrl_hjkl = false })
end, { desc = "btop" })

-- map tab to tab, because distinguish between <C-i>
map("t", "<Tab>", "<Tab>")

-- scroll window horizontally (scroll-horizontal)
-- < reference: https://unix.stackexchange.com/questions/110251/how-to-put-current-line-at-top-center-bottom-of-screen-in-vim
map("n", "[z", "zh", { desc = "scroll left", silent = true }) -- left
map("n", "]z", "zl", { desc = "scroll right", silent = true }) -- right

-- Move lines
map("n", "<Down>", "<cmd>m .+1<CR>==", { desc = "Move down" })
map("n", "<Up>", "<cmd>m .-2<CR>==", { desc = "Move up" })
map("i", "<Down>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move down" })
map("i", "<Up>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move up" })
map("x", "<Down>", ":m '>+1<CR>gv=gv", { desc = "Move down" })
map("x", "<Up>", ":m '<-2<CR>gv=gv", { desc = "Move up" })

-- map("n", "<C-x>", "<C-w>x", { desc = "Exchange window" })
map("n", "<C-q>", function()
  -- close current window if there are more than 1 window
  -- else close current tab if there are more than 1 tab
  -- else close current vim
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd([[close]])
  elseif #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd([[tabclose]])
  else
    vim.cmd([[qa]])
  end
end, { desc = "Super Quit" })

-- map s to <nop>
vim.keymap.set("n", "s", "<nop>", { noremap = true, desc = "split/surround/selection" })
-- Resize with arrows
-- map("n", "s<Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
-- map("n", "s<Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
-- map("n", "s<Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
-- map("n", "s<Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Switch buffer with tab
-- vim.keymap.set("n", "<tab>", "<tab>") -- conflict with <C-i>
-- vim.keymap.set("n", "<tab>", "]b", { desc = "Next buffer", remap = true, silent = true })
-- vim.keymap.set("n", "<s-tab>", "[b", { desc = "Prev buffer", remap = true, silent = true })

-- Tabs management
map("n", "]<tab>", "<cmd>tabn<CR>", { desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabp<CR>", { desc = "Prev Tab" })
map("n", "<leader><tab>s", "<cmd>tab split<CR>", { desc = "Split" })
map("n", "<leader><tab>]", "<cmd>-tabmove<CR>", { desc = "Move to left" })
map("n", "<leader><tab>[", "<cmd>+tabmove<CR>", { desc = "Move to right" })
map("n", "<leader><tab>o", "<cmd>tabonly<CR>", { desc = "Close all other tabs" })
map("n", "<leader><tab>F", "<cmd>tabm 0<CR>", { desc = "Move to first" })
map("n", "<leader><tab>L", "<cmd>tabm<CR>", { desc = "Move to last" })
map("n", "<leader><tab>t", "<cmd>tabs", { desc = "List all tabs" })

map("n", "<leader><TAB>n", "<Cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader><TAB><TAB>", function()
  vim.ui.select(vim.api.nvim_list_tabpages(), {
    prompt = "Select Tab:",
    format_item = function(tabid)
      local wins = vim.api.nvim_tabpage_list_wins(tabid)
      local not_floating_win = function(winid)
        return vim.api.nvim_win_get_config(winid).relative == ""
      end
      wins = vim.tbl_filter(not_floating_win, wins)
      local bufs = {}
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        if buftype ~= "nofile" then
          local fname = vim.api.nvim_buf_get_name(buf)
          table.insert(bufs, vim.fn.fnamemodify(fname, ":t"))
        end
      end
      local tabnr = vim.api.nvim_tabpage_get_number(tabid)
      local cwd = string.format(" %8s: ", vim.fn.fnamemodify(vim.fn.getcwd(-1, tabnr), ":t"))
      local is_current = vim.api.nvim_tabpage_get_number(0) == tabnr and "✸" or " "
      return tabnr .. is_current .. cwd .. table.concat(bufs, ", ")
    end,
  }, function(tabid)
    if tabid ~= nil then
      vim.cmd(tabid .. "tabnext")
    end
  end)
end, { desc = "Select tab" })

-- close unused buffers
local id = vim.api.nvim_create_augroup("startup", {
  clear = false,
})

local persistbuffer = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.fn.setbufvar(bufnr, "bufpersist", 1)
end

vim.api.nvim_create_autocmd({ "BufRead" }, {
  group = id,
  pattern = { "*" },
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI" }, {
      buffer = 0,
      once = true,
      callback = function()
        persistbuffer(bufnr)
      end,
    })
  end,
})

map("n", "<leader>bb", function()
  local curbufnr = vim.api.nvim_get_current_buf()
  local buflist = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(buflist) do
    if vim.bo[bufnr].buflisted and bufnr ~= curbufnr and (vim.fn.getbufvar(bufnr, "bufpersist") ~= 1) then
      vim.cmd("bd " .. tostring(bufnr))
    end
  end
end, { silent = true, desc = "Close unused buffers" })

vim.keymap.set("n", "<C-w>", "<leader>bd", { remap = true, desc = "Close Buffer" })

-- Replace in selection
map("x", "s/", ":s/\\%V", { silent = false, desc = "replace in selection" })
-- search in selection
map("x", "g/", ":/\\%V", { silent = false, desc = "search in selection" })

-- smart deletion, dd
-- It solves the issue, where you want to delete empty line, but dd will override you last yank.
-- Code above will check if u are deleting empty line, if so - use black hole register.
-- [src: https://www.reddit.com/r/neovim/comments/w0jzzv/comment/igfjx5y/?utm_source=share&utm_medium=web2x&context=3]
local function smart_dd()
  if vim.api.nvim_get_current_line():match("^%s*$") then
    return '"_dd'
  else
    return "dd"
  end
end
vim.keymap.set("n", "dd", smart_dd, { noremap = true, expr = true, desc = "Don't yank empty line" })

-- delete current line marks
-- [src: https://github.com/lkhphuc/dotfiles/blob/master/nvim/lua/config/keymaps.lua]
local function delete_marks()
  local cur_line = vim.fn.line(".")
  -- Delete buffer local mark
  for _, mark in ipairs(vim.fn.getmarklist("%")) do
    if mark.pos[2] == cur_line and mark.mark:match("[a-zA-Z]") then
      vim.api.nvim_buf_del_mark(0, string.sub(mark.mark, 2, #mark.mark))
      return
    end
  end
  -- Delete global marks
  local cur_buf = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.pos[1] == cur_buf and mark.pos[2] == cur_line and mark.mark:match("[a-zA-Z]") then
      vim.api.nvim_buf_del_mark(0, string.sub(mark.mark, 2, #mark.mark))
      return
    end
  end
end
vim.keymap.set("n", "dm", delete_marks, { noremap = true, desc = "Delete mark on the current line" })

local layout = require("util.layout")
if layout.is_colemak() then
  require("util.keymaps.colemak")
else
  require("util.keymaps.qwerty")
end
