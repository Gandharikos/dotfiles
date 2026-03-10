{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum nullOr str bool;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  inherit (lib.meta) getExe;
  inherit (config) my;

  waylandChoices = ["hyprland" "niri" "cosmic"];
  xorgChoices = ["i3" "bspwm" "awesome"];
  darwinChoices = ["aerospace"];
in {
  # Top-level GUI enable option
  options.my.gui.enable =
    mkEnableOption "GUI"
    // {
      default = true;
    };

  # Desktop configuration options
  options.my.gui.desktop = {
    enable = mkOption {
      type = bool;
      internal = true;
      readOnly = true;
      default = my.gui.enable;
      description = "Internal option that mirrors my.gui.enable";
    };

    type = mkOption {
      type = nullOr (enum (
        if isLinux
        then ["wayland" "xorg"]
        else if isDarwin
        then ["darwin"]
        else []
      ));
      default =
        if !my.gui.enable
        then null
        else if isLinux
        then "wayland"
        else "darwin";
      description = "The desktop environment type to use";
    };

    default = mkOption {
      type = nullOr (enum (
        if my.gui.desktop.type == "wayland"
        then waylandChoices
        else if my.gui.desktop.type == "xorg"
        then xorgChoices
        else darwinChoices
      ));
      default =
        if !my.gui.enable
        then null
        else if my.gui.desktop.type == "wayland"
        then "hyprland"
        else if my.gui.desktop.type == "xorg"
        then "i3"
        else "aerospace";
      description = "The default window manager limited by desktop.type";
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

  config.assertions = [
    {
      assertion = my.gui.desktop.type != null -> my.gui.enable;
      message = "You can't use gui.desktop.type without gui.enable";
    }
    {
      assertion = my.gui.enable -> my.gui.desktop.type != null;
      message = "You can't use gui.enable without gui.desktop.type";
    }
  ];
}
