{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) time-travel; };
    keymap.mgr.prepend_keymap = [
      # time travel
      {
        on = [
          "z"
          "h"
        ];
        run = "plugin time-travel --args=prev";
        desc = "Go to previous snapshot";
      }
      {
        on = [
          "z"
          "l"
        ];
        run = "plugin time-travel --args=next";
        desc = "Go to next snapshot";
      }
      {
        on = [
          "z"
          "e"
        ];
        run = "plugin time-travel --args=exit";
        desc = "Exit time travel";
      }
    ];
  };
}
