{ config, ... }:
{
  programs.zellij.settings.keybinds._children = with config.my.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "locked"
          "resize"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl r" ];
              _children = [ { SwitchToMode._args = [ "resize" ]; } ];
            };
          }
        ];
      };
    }
    {
      resize._children = [
        {
          bind = {
            _args = [ "-" ];
            _children = [ { Resize._args = [ "Decrease" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              "="
              "+"
            ];
            _children = [ { Resize._args = [ "Increase" ]; } ];
          };
        }
        {
          bind = {
            _args = [ H ];
            _children = [ { Resize._args = [ "Decrease Left" ]; } ];
          };
        }
        {
          bind = {
            _args = [ J ];
            _children = [ { Resize._args = [ "Decrease Down" ]; } ];
          };
        }
        {
          bind = {
            _args = [ K ];
            _children = [ { Resize._args = [ "Decrease Up" ]; } ];
          };
        }
        {
          bind = {
            _args = [ L ];
            _children = [ { Resize._args = [ "Decrease Right" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              h
              "Left"
            ];
            _children = [ { Resize._args = [ "Increase Left" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              j
              "Down"
            ];
            _children = [ { Resize._args = [ "Increase Down" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              k
              "Up"
            ];
            _children = [ { Resize._args = [ "Increase Up" ]; } ];
          };
        }
        {
          bind = {
            _args = [
              l
              "Right"
            ];
            _children = [ { Resize._args = [ "Increase Right" ]; } ];
          };
        }
      ];
    }
  ];
}
