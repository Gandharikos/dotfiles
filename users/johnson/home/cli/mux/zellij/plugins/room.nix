{ pkgs, ... }:
let
  roomWasm = "file:${pkgs.dot.room}/bin/room.wasm";
  launchRoom = {
    LaunchOrFocusPlugin = {
      _args = [ roomWasm ];
      floating = true;
      ignore_case = true;
      quick_jump = true;
    };
  };
in
{
  programs.zellij.settings = {
    plugins.room._props.location = roomWasm;
    keybinds._children = [
      {
        shared_except = {
          _args = [ "locked" ];
          _children = [
            {
              bind = {
                _args = [ "Alt r" ];
                _children = [
                  launchRoom
                ];
              };
            }
          ];
        };
      }
    ];
  };
}
