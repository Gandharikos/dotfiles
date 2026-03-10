{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.lists) elem;
  inherit (config.my.gui.desktop.hyprland) plugins;
  enable = plugins.enable && elem "hyprspace" plugins.list;
  hyprland_settings = config.wayland.windowManager.hyprland.settings;
in {
  config = mkIf enable {
    wayland.windowManager.hyprland = {
      plugins = with pkgs.hyprlandPlugins; [hyprspace];

      settings = {
        bindd = mkAfter [
          "$mainMod, TAB, Toggle Overview, overview:toggle"
          "$mainMod SHIFT, TAB, Toggle Overview (All), overview:toggle, all"
        ];
        plugin.overview = {
          # layout
          gapsIn = 5;
          gapsOut = 5;
          panelHeight = 100;

          # behavior
          autoDrag = false;
          autoScroll = true;
          exitOnClick = true;
          switchOnDrop = true;
          exitOnSwitch = true;
          showNewWorkspace = true;
          centerAligned = true;
          hideTopLayers = true;
          hideOverlayLayers = true;
          drawActiveWorkspace = true;

          panelBorderColor = hyprland_settings.general."col.active_border";
          panelBorderWidth = hyprland_settings.general.border_size;
          panelColor = hyprland_settings.decoration."col.shadow";
          workspaceActiveBackground = hyprland_settings.group.groupbar.col.active;
          workspaceInactiveBackground = hyprland_settings.group.groupbar.col.inactive;
          workspaceActiveBorder = hyprland_settings.group."col.active_border";
          workspaceInactiveBorder = hyprland_settings.group."col.inactive_border";
          workspaceBorderSize = hyprland_settings.general.border_size;
        };
      };
    };
  };
}
