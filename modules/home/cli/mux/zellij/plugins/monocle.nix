{ pkgs, ... }:
let
  monocleWasm = "file:${pkgs.my.monocle}/bin/monocle.wasm";
  launchMonocle = {
    LaunchOrFocusPlugin = {
      _args = [ monocleWasm ];
      floating = true;
      move_to_focusd_tab = true;
    };
  };
in
{
  programs.zellij.settings = {
    plugins.monocle._props.location = monocleWasm;
    keybinds._children = [
      {
        shared_except = {
          _args = [ "locked" ];
          _children = [
            {
              bind = {
                _args = [ "Alt m" ];
                _children = [
                  launchMonocle
                  { SwitchToMode._args = [ "normal" ]; }
                ];
              };
            }
          ];
        };
      }
    ];
  };
}
