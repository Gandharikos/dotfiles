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

  clipboardCopy =
    if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else lib.getExe' pkgs.wl-clipboard "wl-copy";
  # Nvim's clipboard provider may exit before the copy finishes, so copy synchronously, then quit.
  copyModeYank = pkgs.writeText "rex-copy-mode.lua" ''
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        if vim.v.event.operator ~= "y" then
          return
        end
        vim.fn.system({ "${clipboardCopy}" }, table.concat(vim.v.event.regcontents, "\n"))
        vim.schedule(function()
          vim.cmd("qa!")
        end)
      end,
    })
  '';
  copyMode = pkgs.writeShellScript "rex-copy-mode" ''
    scrollback=$(mktemp "''${TMPDIR:-/tmp}/rex-scrollback.XXXXXX")
    trap 'rm -f "$scrollback"' EXIT
    ${lib.getExe config.programs.rex.package} capture -s "$1" -b "$2" --trim --unwrap >"$scrollback"
    ${lib.getExe config.programs.neovim.package} -R + -c "luafile ${copyModeYank}" "$scrollback"
  '';
in
{
  options.my.rex.enable = lib.mkEnableOption "Rex terminal multiplexer";

  config = lib.mkIf cfg.enable {
    programs.rex = {
      enable = true;
      config = ''
        ${bind "space" "client.palette.toggle"}
        rex.bind("ctrl+enter", "pane.split.auto")

        local smart_splits = dofile("${pkgs.vimPlugins.smart-splits-backend-rex}/rex/lua/smart-splits-rex/init.lua")
        smart_splits.setup({ resize_amount = 3 })

        local scroll_keys = { up = "ctrl+b", down = "ctrl+f" }

        local function focused_block_id()
          local view = assert(rex.session.view({}))
          for _, window in ipairs(view.windows or {}) do
            if window.window_id == view.active_window_id then
              return window.focused_block_id
            end
          end
        end

        rex.action{
          name = "smart_scroll_page",
          title = "Scroll Page (Rex or Neovim)",
          repeats = true,
          args = {
            type = "object",
            required = { "direction" },
            properties = { direction = { type = "string", enum = { "up", "down" } } },
          },
          run = function(ctx, args)
            local is_vim, err = smart_splits.is_vim(ctx)
            -- Process detection can yield; do not act on a newly focused pane.
            if is_vim == nil or focused_block_id() ~= ctx.block_id then
              error("smart-scroll: " .. (err or "focused pane changed; retry the key"), 0)
            end
            if is_vim then
              rex.client.queue("pane.send_key", { key = scroll_keys[args.direction] })
            else
              rex.client.queue("client.scroll.page_" .. args.direction)
            end
          end,
        }
        for direction, key in pairs(scroll_keys) do
          rex.bind(key, "smart_scroll_page", { direction = direction })
        end

        rex.action{
          name = "smart_close_pane",
          title = "Close Pane (unless in Vim)",
          run = function(ctx)
            -- Treat failed detection as Vim: forwarding ctrl+q is safer than closing the pane.
            local is_vim = smart_splits.is_vim(ctx) ~= false
            if focused_block_id() ~= ctx.block_id then
              error("smart-close: focused pane changed; retry the key", 0)
            end
            if is_vim then
              rex.client.queue("pane.send_key", { key = "ctrl+q" })
            else
              rex.client.queue("pane.close")
            end
          end,
        }
        rex.bind("ctrl+q", "smart_close_pane")

        -- Rex has no tmux-style copy mode: open the pane's scrollback in Neovim on top of the pane.
        local function find_rect(node, block_id)
          if not node then
            return nil
          end
          if node.block_id == block_id then
            return node.rect
          end
          return node.split and (find_rect(node.split.before, block_id) or find_rect(node.split.after, block_id))
        end

        local function block_rect(block_id)
          local view = assert(rex.session.view({}))
          for _, window in ipairs(view.windows or {}) do
            for _, layer in ipairs(window.layers or {}) do
              local rect = find_rect(layer.layout, block_id)
              if rect then
                return rect
              end
            end
          end
        end

        rex.action{
          name = "copy_mode",
          title = "Copy Mode (Scrollback in Neovim)",
          run = function(ctx)
            local _, err = rex.session.new_layer{
              bounds = block_rect(ctx.block_id) or { 0.1, 0.1, 0.8, 0.8 },
              layout = rex.layout.block{
                flavor = "com.superlogical.terminal.shell",
                options = { command = { "${copyMode}", ctx.session_id, ctx.block_id } },
              },
              focus = true,
            }
            if err then
              error("copy-mode: " .. err, 0)
            end
          end,
        }
        ${bind "escape" "copy_mode"}

        ${bind "f" "client.find.open"}

        rex.bind("${prefix}p", "client.mode.enter", { name = "prompt" })
        rex.bind("prompt/j", "client.prompt.next")
        rex.bind("prompt/k", "client.prompt.previous")
        rex.bind("prompt/escape", "client.mode.exit")

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
        -- Vim-style "only": keys.o follows the layout so Colemak does not collide with split/move right.
        ${bind keys.o "pane.close_others"}
        ${bind (shiftKey keys.O) "client.tab.close_others"}
        ${bind "-" "pane.focus_previous"}
        ${bind "=" "pane.focus_next"}
        ${bind "b" "pane.balance"}
        ${bind "enter" "pane.float"}
        ${bind "shift+enter" "pane.new_floating"}
        ${bind "m" "pane.minimize_floating"}
        ${bind "shift+m" "pane.minimize_all_floating"}
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
