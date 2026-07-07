{ lib, pkgs, ... }:
let
  harpoonWasm = "file:${lib.getExe' pkgs.dot.harpoon "harpoon.wasm"}";
  launchHarpoon = {
    LaunchOrFocusPlugin = {
      _args = [ harpoonWasm ];
      floating = true;
      move_to_focusd_tab = true;
    };
  };
in
{
  programs.zellij.settings = {
    plugins.harpoon._props.location = harpoonWasm;
    keybinds._children = [
      {
        shared_except = {
          _args = [
            "locked"
            "tmux"
            "pane"
          ];
          _children = [
            {
              bind = {
                _args = [ "Alt a" ];
                _children = [
                  launchHarpoon
                ];
              };
            }
          ];
        };
      }
      {
        shared_among = {
          _args = [
            "tmux"
            "pane"
          ];
          _children = [
            {
              bind = {
                _args = [ "a" ];
                _children = [
                  launchHarpoon
                ];
              };
            }
          ];
        };
      }
    ];
  };
}
