{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.lists) elem;
  inherit (lib.my) mkHyprWorkspaces;
  inherit (config.my.gui.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprsplit" plugins.list;
  num_workspaces = config.my.gui.desktop.workspace.number;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprsplit];
      settings = {
        bindd = mkAfter (
          [
            "$mod, D, Swap Active Workspaces, split:swapactiveworkspaces, current + 1"
            "$mod SHIFT, G, Grab Rogue Windows, split:grabroguewindows"
          ]
          ++ (mkHyprWorkspaces
            ["split:workspace" "split:movetoworkspace" "split:movetoworkspacesilent"]
            num_workspaces)
        );
        plugin.hyprsplit = {
          inherit num_workspaces;
          persistent_workspaces = true;
        };
      };
    };
  };
}
