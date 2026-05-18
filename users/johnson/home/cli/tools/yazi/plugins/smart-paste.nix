{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) smart-paste; };
    keymap.mgr.prepend_keymap = [
      {
        desc = "Paste into the hovered directory or CWD";
        on = "p";
        run = "plugin smart-paste";
      }
    ];
  };
}
