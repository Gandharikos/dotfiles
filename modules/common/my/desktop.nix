{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum nullOr str;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  inherit (lib.meta) getExe;
  inherit (config) my;

  waylandChoices = ["hyprland" "niri" "cosmic"];
  xorgChoices = ["i3" "bspwm" "awesome"];
  darwinChoices = ["aerospace"];
in {
  options.my.desktop = {
    enable =
      mkEnableOption "Desktop"
      // {
        default = true;
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
        if !my.desktop.enable
        then null
        else if isLinux
        then "wayland"
        else "darwin";
      description = "The desktop environment type to use";
    };

    default = mkOption {
      type = nullOr (enum (
        if my.desktop.type == "wayland"
        then waylandChoices
        else if my.desktop.type == "xorg"
        then xorgChoices
        else darwinChoices
      ));
      default =
        if !my.desktop.enable
        then null
        else if my.desktop.type == "wayland"
        then "hyprland"
        else if my.desktop.type == "xorg"
        then "i3"
        else "aerospace";
      description = "The default window manager limited by desktop.type";
    };

    exec = mkOption {
      type = str;
      default = getExe (builtins.getAttr my.desktop.default pkgs);
      description = ''
        The command to use for logging in. This is used by the
        `my.desktop.exec` module to determine which command to run.
      '';
    };
  };
  config.assertions = [
    {
      assertion = my.desktop.type != null -> my.desktop.enable;
      message = "You can't use desktop.type without desktop.enable";
    }
    {
      assertion = my.desktop.enable -> my.desktop.type != null;
      message = "You can't use desktop.enable without desktop.type";
    }
  ];
}
