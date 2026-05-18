{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) jump-to-char; };
    keymap.mgr.prepend_keymap = [
      {
        desc = "Jump to char";
        on = "f";
        run = "plugin jump-to-char";
      }
    ];
  };
}
