{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (osConfig.dot.keyboard) keys;
  cfg = config.my.rex;
  prefix = "ctrl+a>";
  shiftKey = key: "shift+${lib.toLower key}";
  bind = key: action: ''rex.bind("${prefix}${key}", "${action}")'';
  bindSplit =
    key: direction: ''rex.bind("${prefix}${key}", "pane.split", { direction = "${direction}" })'';
  bindFocus =
    key: direction:
    ''rex.bind("ctrl+${key}", "smart_splits_focus", { direction = "${direction}", key = "ctrl+${key}" })'';
  bindResize =
    key: direction:
    ''rex.bind("alt+${key}", "smart_splits_resize", { direction = "${direction}", key = "alt+${key}" })'';
in
{
  options.my.rex.enable = lib.mkEnableOption "Rex terminal multiplexer";

  config = lib.mkIf cfg.enable {
    programs.rex = {
      enable = true;
      config = ''
        ${bind "space" "client.palette.toggle"}
        rex.bind("ctrl+enter", "pane.split.auto")

        dofile("${pkgs.vimPlugins.smart-splits-backend-rex}/rex/lua/smart-splits-rex/init.lua").setup({ resize_amount = 3 })

        rex.action{
          name = "smart_close_pane",
          title = "Close Pane (unless in Vim)",
          run = function()
            local process = rex.block.call("com.superlogical.terminal", "process", {})
            local name = process and process.foreground and process.foreground.name
            local vim_processes = {
              vim = true, nvim = true, view = true, gvim = true,
              vimdiff = true, nvimdiff = true,
            }
            if not name or vim_processes[name] then
              rex.client.queue("pane.send_key", { key = "ctrl+q" })
            else
              rex.client.queue("pane.close")
            end
          end,
        }
        rex.bind("ctrl+q", "smart_close_pane")

        -- Tmux prefix: Ctrl+A. Press it twice to send Ctrl+A to the terminal.
        rex.bind("${prefix}ctrl+a", "pane.send_key", { key = "ctrl+a" })
        ${bind "ctrl+r" "client.config.reload"}

        ${bind "t" "client.tab.new"}
        for index = 1, 9 do
          rex.bind("${prefix}" .. index, "client.tab.goto", { index = index })
        end
        ${bind "shift+g" "pane.go_to_directory"}
        ${bind "q" "client.tab.close"}
        ${bind "shift+q" "session.close"}
        ${bind "[" "client.tab.previous"}
        ${bind "]" "client.tab.next"}
        ${bind "shift+[" "client.tab.move.backward"}
        ${bind "shift+]" "client.tab.move.forward"}
        ${bind "s" "session.switch"}
        ${bind "shift+s" "session.new"}
        ${bind "r" "session.refresh"}
        ${bind "tab" "session.previous"}
        ${bind "shift+tab" "session.next"}
        ${bind "z" "pane.zoom"}
        ${bind "x" "pane.close"}
        ${bind "-" "pane.focus_previous"}
        ${bind "=" "pane.focus_next"}
        ${bind "b" "pane.balance"}
        ${bind "enter" "pane.float"}
        ${bind "/" "client.sidebar.toggle"}
        ${bind "." "client.sidebar.activity.toggle"}

        ${bindSplit keys.h "left"}
        ${bindSplit keys.j "down"}
        ${bindSplit keys.k "up"}
        ${bindSplit keys.l "right"}

        ${bindFocus keys.h "left"}
        ${bindFocus keys.j "down"}
        ${bindFocus keys.k "up"}
        ${bindFocus keys.l "right"}

        ${bindResize keys.h "left"}
        ${bindResize keys.j "down"}
        ${bindResize keys.k "up"}
        ${bindResize keys.l "right"}

        ${bind (shiftKey keys.H) "pane.move.left"}
        ${bind (shiftKey keys.J) "pane.move.down"}
        ${bind (shiftKey keys.K) "pane.move.up"}
        ${bind (shiftKey keys.L) "pane.move.right"}

        ${bind "left" "pane.focus.left"}
        ${bind "down" "pane.focus.down"}
        ${bind "up" "pane.focus.up"}
        ${bind "right" "pane.focus.right"}
      '';
    };

    # The Rex app owns the server on macOS; Linux uses a personal user service.
    services.rex.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
