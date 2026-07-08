local generated = {}
local ok, value = pcall(require, "generated")
if ok and type(value) == "table" then
  generated = value
end

local function env(name, default)
  local value = os.getenv(name)
  if value == nil or value == "" then
    return default
  end
  return value
end

local function number_env(name, default)
  local value = tonumber(env(name, ""))
  if value == nil then
    return default
  end
  return value
end

local function merge(...)
  local result = {}
  for _, source in ipairs({ ... }) do
    if type(source) == "table" then
      for key, value in pairs(source) do
        if value ~= nil then
          result[key] = value
        end
      end
    end
  end
  return result
end

local function command(prefix, args)
  if prefix == nil or prefix == "" then
    return nil
  end
  if args == nil or #args == 0 then
    return prefix
  end
  return prefix .. " " .. table.concat(args, " ")
end

local generated_commands = generated.commands or {}
local generated_backends = generated.backends or {}
local generated_theme = generated.theme or {}

local backends = {
  launcher = env("HYPR_LAUNCHER", generated_backends.launcher or "vicinae"),
  shell = env("HYPR_SHELL", generated_backends.shell or "none"),
  shot = env("HYPR_SHOT", generated_backends.shot or "generic"),
}

local base_commands = {
  terminal = env("HYPR_TERMINAL", generated_commands.terminal or "kitty"),
  browser = env("HYPR_BROWSER", generated_commands.browser or "firefox"),
  file_manager = env("HYPR_FILE_MANAGER", generated_commands.file_manager or "dolphin"),
  launcher = env("HYPR_LAUNCHER_CMD", generated_commands.launcher),
  ocr = env(
    "HYPR_OCR_CMD",
    generated_commands.ocr or 'grim -g "$(slurp)" - | tesseract -l eng+chi_sim+chi_tra - - | wl-copy'
  ),
  screenshot_region = env(
    "HYPR_SCREENSHOT_REGION_CMD",
    generated_commands.screenshot_region or 'grim -g "$(slurp)" - | satty --filename -'
  ),
  keyboard_backlight_toggle = env(
    "HYPR_KEYBOARD_BACKLIGHT_TOGGLE_CMD",
    generated_commands.keyboard_backlight_toggle
      or 'brightnessctl --device="*::kbd_backlight" get | grep -qx 0 && brightnessctl --device="*::kbd_backlight" set 100% || brightnessctl --device="*::kbd_backlight" set 0'
  ),
  playerctl = env("HYPR_PLAYERCTL", generated_commands.playerctl or "playerctl"),
  wpctl = env("HYPR_WPCTL", generated_commands.wpctl or "wpctl"),
  brightnessctl = env("HYPR_BRIGHTNESSCTL", generated_commands.brightnessctl or "brightnessctl"),
  noctalia = env("HYPR_NOCTALIA", generated_commands.noctalia or "noctalia msg"),
  dms = env("HYPR_DMS", generated_commands.dms or "dms"),
  dms_ipc = env(
    "HYPR_DMS_IPC",
    generated_commands.dms_ipc or command(generated_commands.dms or "dms", { "ipc", "call" })
  ),
  vicinae = env("HYPR_VICINAE", generated_commands.vicinae or "vicinae"),
  hyprshot = env("HYPR_HYPRSHOT", generated_commands.hyprshot or "hyprshot"),
  grimblast = env("HYPR_GRIMBLAST", generated_commands.grimblast or "grimblast"),
  satty = env("HYPR_SATTY", generated_commands.satty or "satty"),
}

local function fallback_actions(commands)
  return {
    media_toggle = command(commands.playerctl, { "play-pause" }),
    media_previous = command(commands.playerctl, { "previous" }),
    media_next = command(commands.playerctl, { "next" }),
    audio_mute = command(commands.wpctl, { "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" }),
    mic_mute = command(commands.wpctl, { "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle" }),
    volume_up = command(commands.wpctl, { "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "6%+" }),
    volume_down = command(commands.wpctl, { "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "6%-" }),
    brightness_up = command(commands.brightnessctl, { "--exponent", "s", "5%+" }),
    brightness_down = command(commands.brightnessctl, { "--exponent", "s", "5%-" }),
  }
end

local function noctalia_actions(commands)
  return {
    clipboard_toggle = command(commands.noctalia, { "panel-toggle", "clipboard" }),
    shell_launcher_toggle = command(commands.noctalia, { "panel-toggle", "launcher" }),
    system_panel_toggle = command(commands.noctalia, { "panel-toggle", "control-center", "system" }),
    session_panel_toggle = command(commands.noctalia, { "panel-toggle", "session" }),
    control_center_toggle = command(commands.noctalia, { "panel-toggle", "control-center" }),
    dnd_toggle = command(commands.noctalia, { "notification-dnd-toggle" }),
    theme_mode_toggle = command(commands.noctalia, { "theme-mode-toggle" }),
    nightlight_toggle = command(commands.noctalia, { "nightlight-toggle" }),
    caffeine_toggle = command(commands.noctalia, { "caffeine-toggle" }),
    settings_toggle = command(commands.noctalia, { "settings-toggle" }),
    notifications_toggle = command(commands.noctalia, { "panel-toggle", "control-center", "notifications" }),
    lock = command(commands.noctalia, { "session", "lock" }),
    screen_recorder_toggle = command(commands.noctalia, {
      "plugin",
      "noctalia/screen_recorder:service",
      "focused",
      "toggle",
    }),
    media_toggle = command(commands.noctalia, { "media", "toggle" }),
    media_previous = command(commands.noctalia, { "media", "previous" }),
    media_next = command(commands.noctalia, { "media", "next" }),
    audio_mute = command(commands.noctalia, { "volume-mute" }),
    mic_mute = command(commands.noctalia, { "mic-mute" }),
    volume_up = command(commands.noctalia, { "volume-up" }),
    volume_down = command(commands.noctalia, { "volume-down" }),
    brightness_up = command(commands.noctalia, { "brightness-up" }),
    brightness_down = command(commands.noctalia, { "brightness-down" }),
  }
end

local function dms_actions(commands)
  return {
    clipboard_toggle = command(commands.dms_ipc, { "clipboard", "toggle" }),
    shell_launcher_toggle = command(commands.dms_ipc, { "spotlight", "toggle" }),
    system_panel_toggle = command(commands.dms_ipc, { "processlist", "toggle" }),
    session_panel_toggle = command(commands.dms_ipc, { "powermenu", "toggle" }),
    control_center_toggle = command(commands.dms_ipc, { "control-center", "toggle" }),
    dnd_toggle = command(commands.dms_ipc, { "notifications", "toggleDoNotDisturb" }),
    theme_mode_toggle = command(commands.dms_ipc, { "theme", "toggle" }),
    nightlight_toggle = command(commands.dms_ipc, { "night", "toggle" }),
    caffeine_toggle = command(commands.dms_ipc, { "inhibit", "toggle" }),
    settings_toggle = command(commands.dms_ipc, { "settings", "toggle" }),
    notifications_toggle = command(commands.dms_ipc, { "notifications", "toggle" }),
    lock = command(commands.dms_ipc, { "lock", "toggle" }),
    screen_recorder_toggle = command(commands.dms_ipc, { "screenRecorder", "toggleRecording" }),
    media_toggle = command(commands.dms_ipc, { "mpris", "playPause" }),
    media_previous = command(commands.dms_ipc, { "mpris", "previous" }),
    media_next = command(commands.dms_ipc, { "mpris", "next" }),
    audio_mute = command(commands.dms_ipc, { "audio", "mute" }),
    mic_mute = command(commands.dms_ipc, { "audio", "micmute" }),
    volume_up = command(commands.dms_ipc, { "audio", "increment", "2" }),
    volume_down = command(commands.dms_ipc, { "audio", "decrement", "2" }),
    brightness_up = command(commands.dms_ipc, { "brightness", "increment", "5", '""' }),
    brightness_down = command(commands.dms_ipc, { "brightness", "decrement", "5", '""' }),
  }
end

local function shell_actions(commands, shell)
  if shell == "noctalia" then
    return noctalia_actions(commands)
  end
  if shell == "dank-material-shell" then
    return dms_actions(commands)
  end
  return {}
end

local function launcher_actions(commands, launcher, shell)
  if commands.launcher ~= nil then
    return { launcher = commands.launcher }
  end
  if launcher == "shell" then
    if shell == "noctalia" then
      return { launcher = command(commands.noctalia, { "panel-toggle", "launcher" }) }
    end
    if shell == "dank-material-shell" then
      return { launcher = command(commands.dms_ipc, { "spotlight", "toggle" }) }
    end
  end
  if launcher == "vicinae" then
    return { launcher = command(commands.vicinae, { "toggle" }) }
  end
  return {}
end

local function shot_actions(commands, shot, shell)
  if shot == "shell" and shell == "noctalia" then
    return {
      screenshot_region = command(commands.noctalia, { "screenshot-region" }),
      screenshot_output = command(commands.noctalia, { "screenshot-fullscreen", "all" }),
      screenshot_window = command(commands.noctalia, { "screenshot-fullscreen", "pick" }),
    }
  end
  if shot == "shell" and shell == "dank-material-shell" then
    return {
      screenshot_region = command(commands.dms, { "screenshot" }),
    }
  end
  if shot == "hyprshot" then
    return {
      screenshot_region = command(commands.hyprshot, { "--mode", "region", "--raw" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
      screenshot_window = command(commands.hyprshot, { "--mode", "window", "--raw" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
      screenshot_output = command(commands.hyprshot, { "--mode", "output", "--raw" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
    }
  end
  if shot == "grimblast" then
    return {
      screenshot_region = command(commands.grimblast, { "--notify", "copysave", "area", "-" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
      screenshot_window = command(commands.grimblast, { "--notify", "copysave", "active", "-" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
      screenshot_output = command(commands.grimblast, { "--notify", "--cursor", "copysave", "output", "-" })
        .. " | "
        .. command(commands.satty, { "--filename", "-" }),
    }
  end
  if shot == "none" then
    return {}
  end
  return {
    screenshot_region = commands.screenshot_region,
  }
end

local actions = merge(
  fallback_actions(base_commands),
  shell_actions(base_commands, backends.shell),
  shot_actions(base_commands, backends.shot, backends.shell),
  launcher_actions(base_commands, backends.launcher, backends.shell),
  generated_commands.actions
)

local commands = merge(generated_commands, base_commands, { actions = actions })

local default_theme = {
  active_border = "rgb(cba6f7)",
  inactive_border = "rgb(45475a)",
  group_active = "rgb(cba6f7)",
  group_inactive = "rgb(181825)",
  group_locked_active = "rgb(89dceb)",
  group_text = "rgb(cdd6f4)",
  background = "rgb(1e1e2e)",
  shadow = "rgba(1e1e2e99)",
}

local env_theme = {
  active_border = env("HYPR_ACTIVE_BORDER"),
  inactive_border = env("HYPR_INACTIVE_BORDER"),
  group_active = env("HYPR_GROUP_ACTIVE"),
  group_inactive = env("HYPR_GROUP_INACTIVE"),
  group_locked_active = env("HYPR_GROUP_LOCKED_ACTIVE"),
  group_text = env("HYPR_GROUP_TEXT"),
  background = env("HYPR_BACKGROUND"),
  shadow = env("HYPR_SHADOW"),
}

local theme = merge(default_theme, generated_theme, env_theme)

local M = {
  generated = generated,
  backends = backends,
  plugins = generated.plugins or {},
  mod = env("HYPR_MOD", generated.mod or "SUPER"),
  workspaces = number_env("HYPR_WORKSPACES", generated.workspaces or 10),
  theme = theme,
  keys = merge({ h = "h", j = "j", k = "k", l = "l", e = "e", I = "I", N = "N" }, generated.keys),
  commands = commands,
  startup = generated.startup or {},
  monitors = generated.monitors or {},
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
