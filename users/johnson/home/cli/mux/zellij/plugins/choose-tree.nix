{ lib, pkgs, ... }:
let
  chooseTreeWasm = "file:${lib.getExe' pkgs.dot.zellij-choose-tree "zellij-choose-tree.wasm"}";
  launchChooseTree = {
    LaunchOrFocusPlugin = {
      _args = [ chooseTreeWasm ];
      floating = true;
      move_to_focusd_tab = true;
      show_plugins = false;
    };
  };
in
{
  programs.zellij.settings.keybinds._children = [
    {
      tmux._children = [
        {
          bind = {
            _args = [ "S" ];
            _children = [
              launchChooseTree
              { SwitchToMode._args = [ "locked" ]; }
            ];
          };
        }
      ];
    }
  ];
}
