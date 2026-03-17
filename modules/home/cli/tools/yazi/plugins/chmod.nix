{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) chmod; };
    keymap.mgr.prepend_keymap = [
      {
        desc = "Chmod on selected files";
        on = [
          "c"
          "m"
        ];
        run = "plugin chmod";
      }
    ];
  };
}
