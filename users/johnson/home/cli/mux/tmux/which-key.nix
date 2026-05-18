{ lib, ... }:
{
  # tmux-which-key configuration
  # Triggered by: prefix + Space or Ctrl+Space
  xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".text = lib.generators.toYAML { } {
    command_alias_start_index = 200;

    keybindings = {
      prefix_table = "Space";
      root_table = "C-Space";
    };

    title = {
      style = "align=centre,bold";
      prefix = "tmux";
      prefix_style = "fg=green,align=centre,bold";
    };

    position = {
      x = "R";
      y = "P";
    };

    macros = {
      restart-pane = [
        "respawnp -k -c #{pane_current_path}"
        "display \"Pane restarted\""
      ];
      reload-config = [
        "source-file ~/.config/tmux/tmux.conf"
        "display \"Config reloaded\""
      ];
    };

    items = [
      {
        name = "+Windows";
        key = "w";
        menu = [
          {
            name = "New window";
            key = "c";
            command = "new-window -c \"#{pane_current_path}\"";
          }
          {
            name = "Kill window";
            key = "&";
            command = "kill-window";
          }
          {
            name = "Rename window";
            key = ",";
            command = "command-prompt -I \"#W\" \"rename-window '%%'\"";
          }
          {
            name = "Previous window";
            key = "p";
            command = "previous-window";
          }
          {
            name = "Next window";
            key = "n";
            command = "next-window";
          }
          {
            name = "Last window";
            key = "l";
            command = "last-window";
          }
          { separator = true; }
          {
            name = "Choose window";
            key = "w";
            command = "choose-tree -Zw";
          }
        ];
      }
      {
        name = "+Panes";
        key = "p";
        menu = [
          {
            name = "Split horizontal";
            key = "-";
            command = "split-window -v -c \"#{pane_current_path}\"";
          }
          {
            name = "Split vertical";
            key = "|";
            command = "split-window -h -c \"#{pane_current_path}\"";
          }
          {
            name = "Kill pane";
            key = "x";
            command = "kill-pane";
          }
          {
            name = "Zoom pane";
            key = "z";
            command = "resize-pane -Z";
          }
          {
            name = "Respawn pane";
            key = "R";
            macro = "restart-pane";
          }
          { separator = true; }
          {
            name = "Break pane to window";
            key = "!";
            command = "break-pane";
          }
          {
            name = "Next pane";
            key = "o";
            command = "select-pane -t :.+";
          }
          {
            name = "Previous pane";
            key = "O";
            command = "select-pane -t :.-";
          }
        ];
      }
      {
        name = "+Layout";
        key = "l";
        menu = [
          {
            name = "Next layout";
            key = "l";
            command = "next-layout";
            transient = true;
          }
          {
            name = "Even horizontal";
            key = "h";
            command = "select-layout even-horizontal";
          }
          {
            name = "Even vertical";
            key = "v";
            command = "select-layout even-vertical";
          }
          {
            name = "Main horizontal";
            key = "H";
            command = "select-layout main-horizontal";
          }
          {
            name = "Main vertical";
            key = "V";
            command = "select-layout main-vertical";
          }
          {
            name = "Tiled";
            key = "t";
            command = "select-layout tiled";
          }
        ];
      }
      {
        name = "+Sessions";
        key = "s";
        menu = [
          {
            name = "New session";
            key = "c";
            command = "command-prompt -p \"New session name:\" \"new-session -s '%%'\"";
          }
          {
            name = "Kill session";
            key = "x";
            command = "kill-session";
          }
          {
            name = "Rename session";
            key = "r";
            command = "command-prompt -I \"#S\" \"rename-session '%%'\"";
          }
          {
            name = "Choose session";
            key = "s";
            command = "choose-tree -Zs";
          }
          {
            name = "Detach";
            key = "d";
            command = "detach-client";
          }
        ];
      }
      { separator = true; }
      {
        name = "Copy mode";
        key = "[";
        command = "copy-mode";
      }
      {
        name = "Paste buffer";
        key = "]";
        command = "paste-buffer";
      }
      {
        name = "Thumbs";
        key = "Enter";
        command = "run-shell \"#{@thumbs-key}\"";
      }
      { separator = true; }
      {
        name = "+System";
        key = "S";
        menu = [
          {
            name = "Reload config";
            key = "r";
            macro = "reload-config";
          }
          {
            name = "Show messages";
            key = "m";
            command = "show-messages";
          }
          {
            name = "List keys";
            key = "?";
            command = "list-keys";
          }
          {
            name = "Clock";
            key = "t";
            command = "clock-mode";
          }
          { separator = true; }
          {
            name = "Detach";
            key = "d";
            command = "detach-client";
          }
          {
            name = "Detach others";
            key = "D";
            command = "detach-client -a";
          }
        ];
      }
    ];
  };
}
