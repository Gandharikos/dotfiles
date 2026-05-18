{ pkgs, ... }:
{
  programs.yazi = {
    plugins = { inherit (pkgs.yaziPlugins) toggle-pane; };
    keymap.mgr.prepend_keymap = [
      {
        desc = "Maximize or restore the preview pane";
        on = "T";
        run = "plugin toggle-pane max-preview";
      }
    ];
  };
}
