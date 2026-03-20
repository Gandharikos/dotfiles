{ config, ... }:
{
  programs.zellij.settings.keybinds._children = with config.my.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "locked"
          "pane"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl p" ];
              _children = [ { SwitchToMode._args = [ "pane" ]; } ];
            };
          }
        ];
      };
    }
    {
      shared_among = {
        _args = [
          "tmux"
          "pane"
        ];
        _children = [
          {
            bind = {
              _args = [ "q" ];
              _children = [
                { CloseFocus = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "F" ];
              _children = [
                { TogglePaneEmbedOrFloating = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "f" ];
              _children = [
                { ToggleFocusFullscreen = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "c" ];
              _children = [
                { SwitchToMode._args = [ "renamepane" ]; }
                { PaneNameInput._args = [ 0 ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "s" ];
              _children = [
                { NewPane._args = [ "stacked" ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "w" ];
              _children = [
                { ToggleFloatingPanes = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "z" ];
              _children = [
                { ToggleFocusFullscreen = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "p" ];
              _children = [
                { TogglePanePinned = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "g" ];
              _children = [
                { TogglePaneInGroup = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "G" ];
              _children = [
                { ToggleGroupMarking = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
        ];
      };
    }
    {
      pane._children = [
        {
          bind = {
            _args = [
              h
              "Left"
            ];
            _children = [ { MoveFocus._args = [ "Left" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              j
              "Down"
            ];
            _children = [ { MoveFocus._args = [ "Down" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              k
              "Up"
            ];
            _children = [ { MoveFocus._args = [ "Up" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              l
              "Right"
            ];
            _children = [ { MoveFocus._args = [ "Right" ]; } ];
          };
        }
        {
          bind = {
            _args = [ "Tab" ];
            _children = [ { SwitchFocus = { }; } ];
          };
        }
        {
          bind = {
            _args = [ H ];
            _children = [
              { NewPane._args = [ "Left" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ J ];
            _children = [
              { NewPane._args = [ "Down" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ K ];
            _children = [
              { NewPane._args = [ "Up" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ L ];
            _children = [
              { NewPane._args = [ "Right" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
      ];
    }
  ];
}
