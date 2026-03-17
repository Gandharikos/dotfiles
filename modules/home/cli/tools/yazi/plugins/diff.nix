{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) diff; };
    keymap.mgr.prepend_keymap = [
      {
        desc = "Diff the selected w/ the hovered file";
        on = "<C-d>";
        run = "plugin diff";
      }
    ];
  };
}
