{
  lib,
  pkgs,
  config,
  ...
}:
let
  vimZellijNavigatorUri = "file:${pkgs.my.vim-zellij-navigator}/bin/vim-zellij-navigator.wasm";
in
{
  imports = lib.my.scanPaths ./.;
  programs.zellij.settings.keybinds = with config.my.keyboard.keys; {
    _props.clear-defaults = true;
    _children = [
      {
        locked._children = [
          {
            bind = {
              _args = [ "Ctrl g" ];
              _children = [ { SwitchToMode._args = [ "normal" ]; } ];
            };
          }
        ];
      }
      {
        shared_except = {
          _args = [
            "normal"
            "locked"
            "entersearch"
          ];
          _children = [
            {
              bind = {
                _args = [ "enter" ];
                _children = [ { SwitchToMode._args = [ "normal" ]; } ];
              };
            }
          ];
        };
      }
      {
        # shared_except "normal" "locked"
        shared_except = {
          _args = [
            "normal"
            "locked"
            "entersearch"
            "renametab"
            "renamepane"
          ];
          _children = [
            {
              bind = {
                _args = [ "Esc" ];
                _children = [ { SwitchToMode._args = [ "normal" ]; } ];
              };
            }
          ];
        };
      }
      {
        shared_except = {
          _args = [ "locked" ];
          _children = [
            {
              bind = {
                _args = [ "Ctrl g" ];
                _children = [ { SwitchToMode._args = [ "locked" ]; } ];
              };
            }
            # Focus movement
            {
              bind = {
                _args = [ "Ctrl ${h}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "move_focus" ]; }
                        { payload._args = [ "left" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Ctrl ${j}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "move_focus" ]; }
                        { payload._args = [ "down" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Ctrl ${k}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "move_focus" ]; }
                        { payload._args = [ "up" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Ctrl ${l}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "move_focus" ]; }
                        { payload._args = [ "right" ]; }
                      ];
                    };
                  }
                ];
              };
            }

            # Resizing
            {
              bind = {
                _args = [ "Alt ${h}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "resize" ]; }
                        { payload._args = [ "left" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Alt ${j}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "resize" ]; }
                        { payload._args = [ "down" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Alt ${k}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "resize" ]; }
                        { payload._args = [ "up" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Alt ${l}" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ vimZellijNavigatorUri ];
                      _children = [
                        { name._args = [ "resize" ]; }
                        { payload._args = [ "right" ]; }
                      ];
                    };
                  }
                ];
              };
            }
            {
              bind = {
                _args = [ "Alt g" ];
                _children = [
                  {
                    Run = {
                      _args = [
                        "zellij"
                        "run"
                        "--floating"
                        "--"
                        "lazygit"
                      ];
                      close_on_exit = true;
                    };
                  }
                  { SwitchToMode._args = [ "locked" ]; }
                ];
              };
            }
            {
              bind = {
                _args = [ "Alt y" ];
                _children = [
                  {
                    NewPane._args = [ "Left" ];
                  }
                  {
                    Run._args = [ "yazi" ];
                  }
                  { SwitchToMode._args = [ "locked" ]; }
                ];
              };
            }
            {
              bind = {
                _args = [ "Ctrl q" ];
                _children = [
                  { CloseFocus = { }; }
                ];
              };
            }
          ];
        };
      }
    ];
  };
}
