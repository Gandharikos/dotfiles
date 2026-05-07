{ config, ... }:
{
  programs.zellij.settings.keybinds._children = with config.dot.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "locked"
          "move"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl m" ];
              _children = [ { SwitchToMode._args = [ "move" ]; } ];
            };
          }
        ];
      };
    }
    {
      move._children = [
        {
          bind = {
            _args = [ h ];
            _children = [ { MovePane._args = [ "Left" ]; } ];
          };
        }
        {
          bind = {
            _args = [ j ];
            _children = [ { MovePane._args = [ "Down" ]; } ];
          };
        }
        {
          bind = {
            _args = [ k ];
            _children = [ { MovePane._args = [ "Up" ]; } ];
          };
        }
        {
          bind = {
            _args = [ l ];
            _children = [ { MovePane._args = [ "Right" ]; } ];
          };
        }
        {
          bind = {
            _args = [ n ];
            _children = [ { MovePane = { }; } ];
          };
        }
        {
          bind = {
            _args = [ N ];
            _children = [ { MovePaneBackwards = { }; } ];
          };
        }
        {
          bind = {
            _args = [ "Tab" ];
            _children = [ { MovePane = { }; } ];
          };
        }
      ];
    }
  ];
}
