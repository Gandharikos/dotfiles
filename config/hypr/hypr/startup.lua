local M = {}

function M.setup(ctx)
  hl.on("hyprland.start", function()
    for _, cmd in ipairs(ctx.generated.startup or {}) do
      hl.exec_cmd(cmd)
    end
  end)
end

return M
