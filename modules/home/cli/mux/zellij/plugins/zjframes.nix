{ pkgs, ... }:
let
  zjframesWasm = "file:${pkgs.my.zjframes}/bin/zjframes.wasm";
in
{
  programs.zellij.settings = {
    plugins.zjframes._props.location = zjframesWasm;
    load_plugins.zjframes = {
      _props = {
        hide_frame_for_single_pane = true;
        hide_frame_except_for_search = true;
        hide_frame_except_for_scroll = true;
        hide_frame_except_for_fullscreen = true;
      };
    };
  };
}
