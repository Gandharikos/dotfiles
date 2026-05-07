{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  vimZellijNavigatorUri = "file:${pkgs.dot.vim-zellij-navigator}/bin/vim-zellij-navigator.wasm";
in
{
  imports = lib.dot.scanPaths ./.;
  programs.zellij.settings.keybinds = with osConfig.dot.keyboard.keys; {
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
            {
              bind = {
                _args = [ "Ctrl Enter" ];
                _children = [ { NewPane = { }; } ];
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
                        { name._args = [ "move_focus_or_tab" ]; }
                        { payload._args = [ "left" ]; }
                        { move_mod._args = [ "ctrl" ]; }
                        { use_arrow_keys.args = [ "false" ]; }
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
                        { move_mod._args = [ "ctrl" ]; }
                        { use_arrow_keys.args = [ "false" ]; }
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
                        { move_mod._args = [ "ctrl" ]; }
                        { use_arrow_keys.args = [ "false" ]; }
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
                        { name._args = [ "move_focus_or_tab" ]; }
                        { payload._args = [ "right" ]; }
                        { move_mod._args = [ "ctrl" ]; }
                        { use_arrow_keys.args = [ "false" ]; }
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
                        { resize_mod._args = [ "alt" ]; }
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
                        { resize_mod._args = [ "alt" ]; }
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
                        { resize_mod._args = [ "alt" ]; }
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
                        { resize_mod._args = [ "alt" ]; }
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
