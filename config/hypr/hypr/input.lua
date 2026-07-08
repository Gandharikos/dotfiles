local M = {}

function M.setup()
  hl.config({
    input = {
      follow_mouse = 0,
      accel_profile = "flat",
      repeat_rate = 25,
      repeat_delay = 200,
      touchpad = {
        tap_to_click = true,
        tap_and_drag = false,
        drag_lock = 0,
        clickfinger_behavior = true,
        disable_while_typing = true,
        natural_scroll = true,
        scroll_factor = 0.2,
      },
    },
    cursor = {
      no_hardware_cursors = true,
    },
    gestures = {
      workspace_swipe_forever = true,
    },
  })

  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end

return M
