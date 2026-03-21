{ config, ... }:
{
  programs.zellij.settings.keybinds._children = with config.my.keyboard.keys; [
    {
      shared_except = {
        _args = [
          "tmux"
          "locked"
        ];
        _children = [
          {
            bind = {
              _args = [ "Ctrl a" ];
              _children = [ { SwitchToMode._args = [ "Tmux" ]; } ];
            };
          }
        ];
      };
    }
    {
      tmux._children = [
        # create panes
        {
          bind = {
            _args = [ h ];
            _children = [
              { NewPane._args = [ "Left" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ j ];
            _children = [
              { NewPane._args = [ "Down" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ k ];
            _children = [
              { NewPane._args = [ "Up" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ l ];
            _children = [
              { NewPane._args = [ "Right" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ H ];
            _children = [
              { MovePane._args = [ "Left" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ J ];
            _children = [
              { MovePane._args = [ "Down" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ K ];
            _children = [
              { MovePane._args = [ "Up" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ L ];
            _children = [
              { MovePane._args = [ "Right" ]; }
              { SwitchToMode._args = [ "normal" ]; }
            ];
          };
        }
        {
          bind = {
            _args = [ "m" ];
            _children = [
              { NextSwapLayout = { }; }
            ];
          };
        }
        {
          bind = {
            _args = [ "M" ];
            _children = [
              { PreviousSwapLayout = { }; }
            ];
          };
        }
      ];
    }
  ];
}
