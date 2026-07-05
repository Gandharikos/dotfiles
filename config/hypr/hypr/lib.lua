local generated = {}
local ok, value = pcall(require, "generated")
if ok and type(value) == "table" then
  generated = value
end

local commands = generated.commands
  or {
    terminal = "kitty",
    browser = "firefox",
    file_manager = "dolphin",
    launcher = "vicinae toggle",
    ocr = 'grim -g "$(slurp)" - | wl-copy',
    screenshot_region = 'grim -g "$(slurp)" - | satty --filename -',
    noctalia = "noctalia msg",
    keyboard_backlight_toggle = 'brightnessctl --device="*::kbd_backlight" get | grep -qx 0 && brightnessctl --device="*::kbd_backlight" set 100% || brightnessctl --device="*::kbd_backlight" set 0',
    playerctl = "playerctl",
    wpctl = "wpctl",
    brightnessctl = "brightnessctl",
  }

local M = {
  generated = generated,
  mod = generated.mod or "SUPER",
  workspaces = generated.workspaces or 10,
  theme = generated.theme or {},
  keys = generated.keys or { h = "h", j = "j", k = "k", l = "l", e = "e" },
  commands = commands,
}

function M.bind(keys, dispatcher, description, flags)
  local opts = flags or {}
  if description ~= nil then
    opts.description = description
  end
  hl.bind(keys, dispatcher, opts)
end

function M.sh(cmd)
  return hl.dsp.exec_cmd(cmd)
end

return M
