{ config, ... }:
{
  programs.zellij.settings.keybinds._children = with config.my.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "scroll"
          "locked"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl s" ];
              _children = [ { SwitchToMode._args = [ "scroll" ]; } ];
            };
          }
        ];
      };
    }
    {
      scroll._children = [
        {
          bind = {
            _args = [ "Space" ];
            _children = [
              { EditScrollback = { }; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "s" ];
            _children = [
              { SwitchToMode._args = [ "entersearch" ]; }
              { SearchInput._args = [ 0 ]; }
            ];
          };
        }
      ];
    }
    {
      search._children = [
        {
          bind = {
            _args = [ "c" ];
            _children = [ { SearchToggleOption._args = [ "CaseSensitivity" ]; } ];
          };
        }
        {
          bind = {
            _args = [ "o" ];
            _children = [ { SearchToggleOption._args = [ "WholeWord" ]; } ];
          };
        }
        {
          bind = {
            _args = [ "w" ];
            _children = [ { SearchToggleOption._args = [ "Wrap" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              "/"
              n
            ];
            _children = [ { Search._args = [ "down" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              "?"
              N
            ];
            _children = [ { Search._args = [ "up" ]; } ];
          };
        }
      ];
    }
    {
      entersearch._children = [
        {
          bind = {
            _args = [
              "Ctrl c"
              "Esc"
            ];
            _children = [ { SwitchToMode._args = [ "scroll" ]; } ];
          };
        }
        {
          bind = {
            _args = [ "Enter" ];
            _children = [ { SwitchToMode._args = [ "search" ]; } ];
          };
        }
      ];
    }
    {
      shared_among = {
        _args = [
          "scroll"
          "search"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl c" ];
              _children = [
                { ScrollToBottom = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [
                j
                "Down"
              ];
              _children = [ { ScrollDown = { }; } ];
            };
          }
          {
            bind = {
              _args = [
                k
                "Up"
              ];
              _children = [ { ScrollUp = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "g" ];
              _children = [ { ScrollToTop = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "G" ];
              _children = [ { ScrollToBottom = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "d" ];
              _children = [ { HalfPageScrollDown = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "u" ];
              _children = [ { HalfPageScrollUp = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "f" ];
              _children = [ { PageScrollDown = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "b" ];
              _children = [ { PageScrollUp = { }; } ];
            };
          }
        ];
      };
    }
  ];
}
