{
  programs.zellij.settings.keybinds._children = [
    {
      shared_among = {
        _args = [
          "tmux"
          "session"
        ];
        _children = [
          {
            bind = {
              _args = [ "d" ];
              _children = [
                { Detach = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
        ];
      };
    }
    {
      shared_except = {
        _args = [
          "locked"
          "session"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl space" ];
              _children = [ { SwitchToMode._args = [ "session" ]; } ];
            };
          }
        ];
      };
    }
    {
      session._children = [
        # Quit
        {
          bind = {
            _args = [ "q" ];
            _children = [
              { Quit = { }; }
            ];
          };
        }
        {
          bind = {
            _args = [ "a" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "zellij:about" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "c" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "configuration" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "l" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "zellij:layout-manager" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "p" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "plugin-manager" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "s" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "zellij:share" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "Space" ];
            _children = [
              {
                LaunchOrFocusPlugin = {
                  _args = [ "session-manager" ];
                  _children = [
                    { floating = true; }
                    { move_to_focused_tab = true; }
                  ];
                };
              }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
      ];
    }
  ];
}
