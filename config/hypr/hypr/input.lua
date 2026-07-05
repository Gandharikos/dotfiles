local M = {}

function M.setup()
  hl.config({
    input = {
      follow_mouse = 1,
      accel_profile = "flat",
      repeat_rate = 25,
      repeat_delay = 200,
      touchpad = {
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
