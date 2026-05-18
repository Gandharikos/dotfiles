{
  osConfig,
  ...
}:
{
  programs.zellij.settings.keybinds._children = with osConfig.dot.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "locked"
          "tab"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl t" ];
              _children = [ { SwitchToMode._args = [ "tab" ]; } ];
            };
          }
        ];
      };
    }
    {
      shared_among = {
        _args = [
          "tmux"
          "tab"
        ];
        _children = [
          {
            bind = {
              _args = [ "x" ];
              _children = [
                { CloseTab = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "Tab" ];
              _children = [ { ToggleTab = { }; } ];
            };
          }
          {
            bind = {
              _args = [ "t" ];
              _children = [
                { NewTab = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          # Tab Operations
          {
            bind = {
              _args = [ "r" ];
              _children = [
                { SwitchToMode._args = [ "renametab" ]; }
                { TabNameInput._args = [ 0 ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "1" ];
              _children = [
                { GoToTab._args = [ 1 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "2" ];
              _children = [
                { GoToTab._args = [ 2 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "3" ];
              _children = [
                { GoToTab._args = [ 3 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "4" ];
              _children = [
                { GoToTab._args = [ 4 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "5" ];
              _children = [
                { GoToTab._args = [ 5 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "6" ];
              _children = [
                { GoToTab._args = [ 6 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "7" ];
              _children = [
                { GoToTab._args = [ 7 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "8" ];
              _children = [
                { GoToTab._args = [ 8 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "9" ];
              _children = [
                { GoToTab._args = [ 9 ]; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "{" ];
              _children = [
                { BreakPaneLeft = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "}" ];
              _children = [
                { BreakPaneRight = { }; }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
          {
            bind = {
              _args = [ "]" ];
              _children = [
                { GoToNextTab = { }; }
              ];
            };
          }
          {
            bind = {
              _args = [ "[" ];
              _children = [
                { GoToPreviousTab = { }; }
              ];
            };
          }
        ];
      };
    }
    {
      tab._children = [
        {
          bind = {
            _args = [ "b" ];
            _children = [
              { BreakPane = { }; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [
              h
              k
              "Left"
              "Up"
            ];
            _children = [ { GoToPreviousTab = { }; } ];
          };
        }
        {
          bind = {
            _args = [
              j
              l
              "Right"
              "Down"
            ];
            _children = [ { GoToNextTab = { }; } ];
          };
        }
        {
          bind = {
            _args = [ "s" ];
            _children = [
              { ToggleActiveSyncTab = { }; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "q" ];
            _children = [
              { CloseTab = { }; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
      ];
    }
  ];
}
