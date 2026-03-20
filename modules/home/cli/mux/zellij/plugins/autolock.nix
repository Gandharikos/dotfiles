{ pkgs, ... }:
let
  autolockWasm = "file:${pkgs.my.zellij-autolock}/bin/zellij-autolock.wasm";
in
{
  programs.zellij.settings = {
    plugins.autolock = {
      _props.location = autolockWasm;
      # automatically lock when these processes are active
      is_enabled = true;
      triggers = "nvim|vim|yazi|atuin|git|fzf";
      reaction_seconds = "0.3";
    };
    load_plugins = {
      autolock = [ ];
    };
    keybinds._children = [
      {
        normal._children = [
          {
            bind = {
              _args = [ "Enter" ];
              _children = [
                { WriteChars = "\\u{000D}"; }
                { MessagePlugin._args = [ "autolock" ]; }
              ];
            };
          }
        ];
      }
      {
        locked._children = [
          {
            bind = {
              _args = [ "Alt z" ];
              _children = [
                {
                  MessagePlugin = {
                    _args = [ "autolock" ];
                    payload = "disable";
                  };
                }
                { SwitchToMode._args = [ "normal" ]; }
              ];
            };
          }
        ];
      }
      {
        shared._children = [
          {
            bind = {
              _args = [ "Alt Shift z" ];
              _children = [
                {
                  MessagePlugin = {
                    _args = [ "autolock" ];
                    payload = "enable";
                  };
                }
              ];
            };
          }
        ];
      }
      {
        shared_except = {
          _args = [ "locked" ];
          _children = [
            {
              bind = {
                _args = [ "Alt z" ];
                _children = [
                  {
                    MessagePlugin = {
                      _args = [ "autolock" ];
                      payload = "disable";
                    };
                  }
                  { SwitchToMode._args = [ "locked" ]; }
                ];
              };
            }
          ];
        };
      }
    ];
  };
}
