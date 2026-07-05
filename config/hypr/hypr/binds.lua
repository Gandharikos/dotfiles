local M = {}

function M.setup(ctx)
  local bind = ctx.bind
  local sh = ctx.sh
  local mod = ctx.mod
  local keys = ctx.keys
  local commands = ctx.commands

  local function noctalia(args)
    return sh(commands.noctalia .. " " .. args)
  end

  bind(mod .. " + Return", sh(commands.terminal), "Launch Terminal")
  bind(mod .. " + B", sh(commands.browser), "Launch Browser")
  bind(mod .. " + " .. keys.e, sh(commands.file_manager), "Launch File Manager")
  bind(mod .. " + Space", sh(commands.launcher), "Launch App Launcher")
  bind(mod .. " + Q", hl.dsp.window.close({}), "Close Window")
  bind(mod .. " + SHIFT + Q", hl.dsp.window.kill({}), "Force Close Window")
  bind(mod .. " + SHIFT + Escape", sh("uwsm stop"), "Exit Hyprland")

  bind(mod .. " + " .. keys.h, hl.dsp.layout("focus l"), "Focus Column Left")
  bind(mod .. " + " .. keys.l, hl.dsp.layout("focus r"), "Focus Column Right")
  bind(mod .. " + " .. keys.k, hl.dsp.focus({ direction = "u" }), "Focus Up")
  bind(mod .. " + " .. keys.j, hl.dsp.focus({ direction = "d" }), "Focus Down")
  bind(mod .. " + SHIFT + " .. keys.h, hl.dsp.layout("swapcol l"), "Move Column Left")
  bind(mod .. " + SHIFT + " .. keys.l, hl.dsp.layout("swapcol r"), "Move Column Right")
  bind(mod .. " + SHIFT + " .. keys.k, hl.dsp.window.move({ direction = "u" }), "Move Window Up")
  bind(mod .. " + SHIFT + " .. keys.j, hl.dsp.window.move({ direction = "d" }), "Move Window Down")
  bind(mod .. " + CTRL + " .. keys.h, hl.dsp.layout("consume_or_expel prev"), "Consume or Expel Left")
  bind(mod .. " + CTRL + " .. keys.l, hl.dsp.layout("consume_or_expel next"), "Consume or Expel Right")
  bind(mod .. " + T", hl.dsp.layout("promote"), "Promote to Column")

  bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Fullscreen")
  bind(mod .. " + M", hl.dsp.layout("fit active"), "Maximize Column")
  bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), "Toggle Floating")
  bind(mod .. " + P", hl.dsp.window.pseudo({}), "Toggle Pseudotile")
  bind(mod .. " + SHIFT + P", hl.dsp.window.pin({ action = "toggle" }), "Toggle Pin")
  bind(mod .. " + C", hl.dsp.layout("fit active"), "Fit Active Column")
  bind(mod .. " + R", hl.dsp.layout("colresize +conf"), "Next Column Width")
  bind(mod .. " + SHIFT + R", hl.dsp.layout("fit expand"), "Expand Column")
  bind(mod .. " + Minus", hl.dsp.layout("colresize -0.05"), "Narrow Column", { repeating = true })
  bind(mod .. " + Equal", hl.dsp.layout("colresize +0.05"), "Widen Column", { repeating = true })

  bind(mod .. " + Comma", hl.dsp.focus({ monitor = "l" }), "Focus Monitor Left")
  bind(mod .. " + Period", hl.dsp.focus({ monitor = "r" }), "Focus Monitor Right")
  bind(mod .. " + SHIFT + Comma", hl.dsp.workspace.move({ monitor = "l" }), "Move Workspace to Monitor Left")
  bind(mod .. " + SHIFT + Period", hl.dsp.workspace.move({ monitor = "r" }), "Move Workspace to Monitor Right")
  bind(mod .. " + BracketLeft", hl.dsp.focus({ workspace = "-1", on_current_monitor = true }), "Previous Workspace")
  bind(mod .. " + BracketRight", hl.dsp.focus({ workspace = "+1", on_current_monitor = true }), "Next Workspace")
  bind(
    mod .. " + SHIFT + BracketLeft",
    hl.dsp.window.move({ workspace = "-1", follow = true }),
    "Move Window to Previous Workspace"
  )
  bind(
    mod .. " + SHIFT + BracketRight",
    hl.dsp.window.move({ workspace = "+1", follow = true }),
    "Move Window to Next Workspace"
  )
  bind(mod .. " + Backspace", hl.dsp.focus({ workspace = "previous", on_current_monitor = true }), "Previous Workspace")
  bind(mod .. " + Grave", hl.dsp.workspace.toggle_special("special"), "Toggle Special Workspace")
  bind(
    mod .. " + SHIFT + Grave",
    hl.dsp.window.move({ workspace = "special:special", follow = true }),
    "Move to Special Workspace"
  )
  bind(mod .. " + V", noctalia("panel-toggle clipboard"), "Toggle Noctalia Clipboard")
  bind(mod .. " + W", noctalia("panel-toggle launcher"), "Toggle Noctalia Launcher")
  bind(mod .. " + Escape", noctalia("panel-toggle control-center system"), "Toggle Noctalia System Panel")
  bind(mod .. " + X", noctalia("panel-toggle session"), "Toggle Noctalia Session Panel")
  bind(mod .. " + CTRL + C", noctalia("panel-toggle control-center"), "Toggle Noctalia Control Center")
  bind(mod .. " + SHIFT + D", noctalia("notification-dnd-toggle"), "Toggle Do Not Disturb")
  bind(mod .. " + SHIFT + T", noctalia("theme-mode-toggle"), "Toggle Theme Mode")
  bind(mod .. " + SHIFT + " .. keys.N, noctalia("nightlight-toggle"), "Toggle Night Light")
  bind(mod .. " + " .. keys.I, noctalia("caffeine-toggle"), "Toggle Caffeine")
  bind("ALT + Comma", noctalia("settings-toggle"), "Toggle Noctalia Settings")
  bind(mod .. " + Apostrophe", noctalia("panel-toggle control-center notifications"), "Toggle Noctalia Notifications")
  bind(mod .. " + ALT + L", noctalia("session lock"), "Lock Session")
  bind("F10", noctalia("plugin noctalia/screen_recorder:service focused toggle"), "Toggle Noctalia Screen Recorder")

  for i = 1, ctx.workspaces do
    local key = tostring(i % 10)
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i, on_current_monitor = true }), "Focus Workspace " .. i)
    bind(
      mod .. " + SHIFT + " .. key,
      hl.dsp.window.move({ workspace = i, follow = true }),
      "Move Window to Workspace " .. i
    )
    bind(
      mod .. " + CTRL + " .. key,
      hl.dsp.window.move({ workspace = i, follow = false }),
      "Move Window to Workspace " .. i .. " Silently"
    )
  end

  bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move Window", { mouse = true })
  bind(mod .. " + ALT + mouse:272", hl.dsp.window.resize(), "Resize Window", { mouse = true })
  bind("Print", sh(commands.screenshot_region), "Screenshot Region")
  bind(mod .. " + Print", sh(commands.ocr), "OCR Selection")
  bind("XF86Favorites", sh(commands.ocr), "OCR Selection")

  bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }), "Cycle Next Window")
  bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }), "Cycle Previous Window")

  bind("XF86AudioPlay", noctalia("media toggle"), "Play/Pause", { locked = true })
  bind("XF86AudioPause", noctalia("media toggle"), "Play/Pause", { locked = true })
  bind("XF86AudioPrev", noctalia("media previous"), "Previous Track", { locked = true })
  bind("XF86AudioNext", noctalia("media next"), "Next Track", { locked = true })
  bind("XF86AudioMute", noctalia("volume-mute"), "Mute Audio", { locked = true })
  bind("XF86AudioMicMute", noctalia("mic-mute"), "Mute Microphone", { locked = true })
  bind("XF86AudioRaiseVolume", noctalia("volume-up"), "Volume Up", { locked = true, repeating = true })
  bind("XF86AudioLowerVolume", noctalia("volume-down"), "Volume Down", { locked = true, repeating = true })
  bind("XF86MonBrightnessUp", noctalia("brightness-up"), "Brightness Up", { locked = true, repeating = true })
  bind("XF86MonBrightnessDown", noctalia("brightness-down"), "Brightness Down", { locked = true, repeating = true })
  bind("XF86KbdLightOnOff", sh(commands.keyboard_backlight_toggle), "Toggle Keyboard Backlight", { locked = true })
  bind(
    "XF86KbdBrightnessUp",
    sh(commands.brightnessctl .. " --device='*::kbd_backlight' s 10%+"),
    "Keyboard Brightness Up",
    { locked = true, repeating = true }
  )
  bind(
    "XF86KbdBrightnessDown",
    sh(commands.brightnessctl .. " --device='*::kbd_backlight' s 10%-"),
    "Keyboard Brightness Down",
    { locked = true, repeating = true }
  )
end

return M
