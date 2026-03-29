{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum str;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (lib.meta) getExe;
  inherit (config) my;

  waylandChoices = [
    "hyprland"
    "niri"
    "cosmic"
  ];
  uwsmChoices = [
    "hyprland"
    "niri"
  ];
  xorgChoices = [
    "i3"
    "bspwm"
    "awesome"
  ];
  darwinChoices = [ "aerospace" ];
in
{
  # Top-level GUI enable option
  options.my.gui.enable = mkEnableOption "GUI" // {
    default = true;
  };

  # Desktop configuration options
  options.my.gui.desktop = {
    type = mkOption {
      type = enum (
        if isLinux then
          [
            "wayland"
            "xorg"
          ]
        else
          [ "darwin" ]
      );
      default = if isLinux then "wayland" else "darwin";
      description = "The desktop environment type to use";
    };

    wayland.enable = mkEnableOption "Wayland desktop" // {
      default = my.gui.enable && my.gui.desktop.type == "wayland";
      internal = true;
      readOnly = true;
    };

    xorg.enable = mkEnableOption "Xorg desktop" // {
      default = my.gui.enable && my.gui.desktop.type == "xorg";
      internal = true;
      readOnly = true;
    };

    default = mkOption {
      type = enum (
        if my.gui.desktop.type == "wayland" then
          waylandChoices
        else if my.gui.desktop.type == "xorg" then
          xorgChoices
        else
          darwinChoices
      );
      default =
        if my.gui.desktop.type == "wayland" then
          "niri"
        else if my.gui.desktop.type == "xorg" then
          "i3"
        else
          "aerospace";
      description = "The default window manager limited by desktop.type";
    };

    uwsm.enable = mkEnableOption "UWSM-managed desktop session" // {
      default = my.gui.desktop.wayland.enable && builtins.elem my.gui.desktop.default uwsmChoices;
      internal = true;
      readOnly = true;
    };

    exec = mkOption {
      type = str;
      default = getExe (builtins.getAttr my.gui.desktop.default pkgs);
      description = ''
        The command to use for logging in. This is used by the
        `my.gui.desktop.exec` module to determine which command to run.
      '';
    };
  };
}
