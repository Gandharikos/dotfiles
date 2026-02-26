{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum nullOr str int float;
  inherit (lib.meta) getExe;
  inherit (lib.my) withUWSM isHyprland;
  inherit (config.my) terminal;
in {
  imports = lib.my.scanPaths ./.;
  options.my.terminal = {
    name = mkOption {
      type = nullOr str;
      default = null;
    };
    default = mkOption {
      type = nullOr (enum [
        "wzeterm"
        "ghostty"
        "kitty"
        "warp"
      ]);
      default =
        if config.my.desktop.enable
        then "ghostty"
        else null;
      description = "The terminal to use";
    };
    exec = mkOption {
      type = str;
      default =
        if isHyprland config
        then withUWSM pkgs terminal.default
        else getExe (builtins.getAttr terminal.default pkgs);
      description = ''
        The command to use for the terminal. This is used by the
        `my.terminal` module to determine which command to run.
      '';
    };
    size = mkOption {
      type = int;
      default =
        if config.my.machine.type == "laptop"
        then 15
        else 12;
      description = ''
        The font size to use for the terminal. This is used by the
        `my.terminal` module to determine which font size to use.
      '';
    };
    font = mkOption {
      type = str;
      default = "JetBrainsMono Nerd Font Mono";
      description = ''
        The font to use for the terminal. This is used by the
        `my.terminal` module to determine which font to use.
      '';
    };
    padding = mkOption {
      type = int;
      default = 5;
      description = ''
        The padding to use for the terminal. This is used by the
        `my.terminal` module to determine which padding to use.
      '';
    };
    opacity = mkOption {
      type = float;
      default = 0.95;
      description = ''
        The opacity to use for the terminal. This is used by the
        `my.terminal` module to determine which opacity to use.
      '';
    };
  };

  config = mkIf (terminal.default != null) {
    home.sessionVariables = {TERMINAL = "${terminal.default}";};
  };
}
