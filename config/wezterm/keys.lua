local wezterm = require("wezterm")

local act = wezterm.action
local M = {}

-- M.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
M.mod = "SHIFT|CTRL"
M.smart_split = wezterm.action_callback(function(window, pane)
  local dim = pane:get_dimensions()
  if dim.pixel_height > dim.pixel_width then
    window:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
  else
    window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
  end
end)

M.smart_close = function(pane_or_window, mods, key)
  return wezterm.action_callback(function(window, pane)
    if M.is_vim(pane) then
      window:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      if pane_or_window == "pane" then
        window:perform_action(act.CloseCurrentPane({ confirm = true }), pane)
      else
        window:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
      end
    end
  end)
end

---@param config Config
function M.setup(config)
  config.disable_default_key_bindings = true
  -- config.leader = M.leader
  config.keys = {
    -- { mods = "LEADER", key = "a", action = act.SendKey({ key = "a", mods = "CTRL" }) },
    -- Scrollback
    { mods = M.mod, key = "i", action = act.ScrollByPage(-0.5) },
    { mods = M.mod, key = "e", action = act.ScrollByPage(0.5) },
    { mods = M.mod, key = "o", action = act({ ActivateTabRelative = 1 }) },
    { mods = M.mod, key = "n", action = act({ ActivateTabRelative = -1 }) },
    -- New Tab
    { mods = M.mod, key = "t", action = act.SpawnTab("CurrentPaneDomain") },
    -- close pane
    { mods = "CTRL", key = "q", action = M.smart_close("pane", "CTRL", "q") },
    -- close pane
    -- { mods = "CTRL", key = "w", action = M.smart_close("tab", "CTRL", "w") },
    -- Splits
    { mods = M.mod, key = "Enter", action = M.smart_split },
    -- {
    -- 	mods = M.mod,
    -- 	key = "n",
    -- 	action = act.SplitPane({ direction = "Left", size = { Percent = 50 } }),
    -- },
    -- {
    -- 	mods = M.mod,
    -- 	key = "e",
    -- 	action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }),
    -- },
    -- {
    -- 	mods = M.mod,
    -- 	key = "i",
    -- 	action = act.SplitPane({ direction = "Up", size = { Percent = 50 } }),
    -- },
    -- {
    -- 	mods = M.mod,
    -- 	key = "o",
    -- 	action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }),
    -- },
    -- Move Tabs
    { mods = M.mod, key = ">", action = act.MoveTabRelative(1) },
    { mods = M.mod, key = "<", action = act.MoveTabRelative(-1) },
    -- Activate Tabs
    { mods = M.mod, key = "}", action = act({ ActivateTabRelative = 1 }) },
    { mods = M.mod, key = "{", action = act({ ActivateTabRelative = -1 }) },
    { mods = M.mod, key = "l", action = act.RotatePanes("Clockwise") },
    -- show the pane selection mode, but have it swap the active and selected panes
    { mods = M.mod, key = "s", action = act.PaneSelect({ mode = "SwapWithActive" }) },
    -- Clipboard
    { mods = M.mod, key = "c", action = act.CopyTo("Clipboard") },
    { mods = M.mod, key = "Space", action = act.QuickSelect },
    { mods = M.mod, key = "x", action = act.ActivateCopyMode },
    { mods = M.mod, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
    { mods = M.mod, key = "v", action = act.PasteFrom("Clipboard") },
    { mods = M.mod, key = "z", action = act.TogglePaneZoomState },
    { mods = M.mod, key = "p", action = act.ActivateCommandPalette },
    { mods = M.mod, key = "?", action = act.ShowDebugOverlay },
    { mods = M.mod, key = "_", action = act.DecreaseFontSize },
    { mods = M.mod, key = "+", action = act.IncreaseFontSize },
    -- extended keys
    -- { mods = "CTRL", key = "h", action = act.SendString("\x1b[104;5u") },
    -- { mods = "CTRL", key = "m", action = act.SendString("\x1b[109;5u") },
    -- { mods = "CTRL", key = "i", action = act.SendString("\x1b[105;5u") },
    -- { mods = "CTRL", key = "Enter", action = act.SendString("\x1b[105;5u") },
    -- { mods = "SHIFT", key = "\r", action = act.SendString("\033[\015;2u") },
  }
  config.key_tables = {
    copy_mode = {
      { key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      {
        key = "Tab",
        mods = "SHIFT",
        action = act.CopyMode("MoveBackwardWord"),
      },
      {
        key = "Enter",
        mods = "NONE",
        action = act.CopyMode("MoveToStartOfNextLine"),
      },
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      {
        key = "Space",
        mods = "NONE",
        action = act.CopyMode({ SetSelectionMode = "Cell" }),
      },
      {
        key = "$",
        mods = "NONE",
        action = act.CopyMode("MoveToEndOfLineContent"),
      },
      {
        key = "$",
        mods = "SHIFT",
        action = act.CopyMode("MoveToEndOfLineContent"),
      },
      { key = "n", mods = "NONE", action = act.CopyMode("MoveLeft") },
      { key = "e", mods = "NONE", action = act.CopyMode("MoveDown") },
      { key = "i", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "o", mods = "NONE", action = act.CopyMode("MoveRight") },
      {
        key = "O",
        mods = "NONE",
        action = act.CopyMode("MoveToStartOfLineContent"),
      },
      {
        key = "O",
        mods = "SHIFT",
        action = act.CopyMode("MoveToEndOfLineContent"),
      },
      {
        key = "N",
        mods = "NONE",
        action = act.CopyMode("MoveToEndOfLineContent"),
      },
      {
        key = "N",
        mods = "SHIFT",
        action = act.CopyMode("MoveToStartOfLineContent"),
      },
      { key = "I", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
      {
        key = "I",
        mods = "SHIFT",
        action = act.CopyMode("MoveToViewportTop"),
      },
      {
        key = "E",
        mods = "NONE",
        action = act.CopyMode("MoveToViewportBottom"),
      },
      {
        key = "E",
        mods = "SHIFT",
        action = act.CopyMode("MoveToViewportBottom"),
      },
      {
        key = "j",
        mods = "NONE",
        action = act.CopyMode("MoveForwardWordEnd"),
      },
      {
        key = "L",
        mods = "NONE",
        action = act.CopyMode("MoveToSelectionOtherEndHoriz"),
      },
      {
        key = "L",
        mods = "SHIFT",
        action = act.CopyMode("MoveToSelectionOtherEndHoriz"),
      },
      {
        key = "l",
        mods = "NONE",
        action = act.CopyMode("MoveToSelectionOtherEnd"),
      },
      { key = ":", mods = "NONE", action = act.CopyMode("JumpReverse") },
      { key = ":", mods = "SHIFT", action = act.CopyMode("JumpReverse") },
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
      {
        key = "F",
        mods = "NONE",
        action = act.CopyMode({ JumpBackward = { prev_char = false } }),
      },
      {
        key = "F",
        mods = "SHIFT",
        action = act.CopyMode({ JumpBackward = { prev_char = false } }),
      },
      {
        key = "G",
        mods = "NONE",
        action = act.CopyMode("MoveToScrollbackBottom"),
      },
      {
        key = "G",
        mods = "SHIFT",
        action = act.CopyMode("MoveToScrollbackBottom"),
      },
      {
        key = "M",
        mods = "NONE",
        action = act.CopyMode("MoveToViewportMiddle"),
      },
      {
        key = "M",
        mods = "SHIFT",
        action = act.CopyMode("MoveToViewportMiddle"),
      },
      {
        key = "T",
        mods = "NONE",
        action = act.CopyMode({ JumpBackward = { prev_char = true } }),
      },
      {
        key = "T",
        mods = "SHIFT",
        action = act.CopyMode({ JumpBackward = { prev_char = true } }),
      },
      {
        key = "V",
        mods = "NONE",
        action = act.CopyMode({ SetSelectionMode = "Line" }),
      },
      {
        key = "V",
        mods = "SHIFT",
        action = act.CopyMode({ SetSelectionMode = "Line" }),
      },
      {
        key = "^",
        mods = "NONE",
        action = act.CopyMode("MoveToStartOfLineContent"),
      },
      {
        key = "^",
        mods = "SHIFT",
        action = act.CopyMode("MoveToStartOfLineContent"),
      },
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      { key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
      { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
      { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
      {
        key = "d",
        mods = "CTRL",
        action = act.CopyMode({ MoveByPage = 0.5 }),
      },
      {
        key = "f",
        mods = "NONE",
        action = act.CopyMode({ JumpForward = { prev_char = false } }),
      },
      { key = "f", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
      { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
      {
        key = "g",
        mods = "NONE",
        action = act.CopyMode("MoveToScrollbackTop"),
      },
      { key = "g", mods = "CTRL", action = act.CopyMode("Close") },
      {
        key = "m",
        mods = "ALT",
        action = act.CopyMode("MoveToStartOfLineContent"),
      },
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
      {
        key = "t",
        mods = "NONE",
        action = act.CopyMode({ JumpForward = { prev_char = true } }),
      },
      {
        key = "u",
        mods = "CTRL",
        action = act.CopyMode({ MoveByPage = -0.5 }),
      },
      {
        key = "v",
        mods = "NONE",
        action = act.CopyMode({ SetSelectionMode = "Cell" }),
      },
      {
        key = "v",
        mods = "CTRL",
        action = act.CopyMode({ SetSelectionMode = "Block" }),
      },
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      {
        key = "y",
        mods = "NONE",
        action = act.Multiple({
          { CopyTo = "ClipboardAndPrimarySelection" },
          { CopyMode = "Close" },
        }),
      },
      { key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
      { key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
      {
        key = "End",
        mods = "NONE",
        action = act.CopyMode("MoveToEndOfLineContent"),
      },
      {
        key = "Home",
        mods = "NONE",
        action = act.CopyMode("MoveToStartOfLine"),
      },
      { key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
      {
        key = "LeftArrow",
        mods = "ALT",
        action = act.CopyMode("MoveBackwardWord"),
      },
      {
        key = "RightArrow",
        mods = "NONE",
        action = act.CopyMode("MoveRight"),
      },
      {
        key = "RightArrow",
        mods = "ALT",
        action = act.CopyMode("MoveForwardWord"),
      },
      { key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
    },
  }
end

function M.is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true" or pane:get_foreground_process_name():find("n?vim")
end

return M
