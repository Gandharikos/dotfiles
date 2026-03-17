{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    enum
    nullOr
    str
    int
    float
    listOf
    coercedTo
    ;
  inherit (lib.meta) getExe;
  inherit (lib.strings) escapeShellArgs hasInfix;
  inherit (lib.my) withUWSMArgs;
  inherit (config.my.gui) desktop terminal;
  commandType = coercedTo str (
    value:
    if hasInfix " " value then
      throw ''
        `my.gui.terminal.command` accepts either an argv list or a single
        program path. Use a list for commands with arguments.
      ''
    else
      [ value ]
  ) (listOf str);
in
{
  imports = lib.my.scanPaths ./.;

  options.my.gui.terminal = {
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
      default = if config.my.gui.enable then "ghostty" else null;
      description = "The terminal to use";
    };

    command = mkOption {
      type = commandType;
      default =
        if terminal.default == null then
          [ ]
        else if desktop.uwsm.enable then
          withUWSMArgs pkgs terminal.default
        else
          [
            getExe
            (builtins.getAttr terminal.default pkgs)
          ];
      description = ''
        The argv form of the terminal command. This is used by
        compositors like Niri that expect a program and its arguments
        as a list instead of a shell string.
      '';
    };

    exec = mkOption {
      type = str;
      default = escapeShellArgs terminal.command;
      internal = true;
      readOnly = true;
      description = ''
        The shell-escaped terminal command derived from
        `my.gui.terminal.command`.
      '';
    };

    size = mkOption {
      type = int;
      default = if config.my.machine.type == "laptop" then 15 else 12;
      description = ''
        The font size to use for the terminal. This is used by the
        `my.gui.terminal` module to determine which font size to use.
      '';
    };

    font = mkOption {
      type = str;
      default = "JetBrainsMono Nerd Font Mono";
      description = ''
        The font to use for the terminal. This is used by the
        `my.gui.terminal` module to determine which font to use.
      '';
    };

    padding = mkOption {
      type = int;
      default = 5;
      description = ''
        The padding to use for the terminal. This is used by the
        `my.gui.terminal` module to determine which padding to use.
      '';
    };

    opacity = mkOption {
      type = float;
      default = 0.85;
      description = ''
        The opacity to use for the terminal. This is used by the
        `my.gui.terminal` module to determine which opacity to use.
      '';
    };
  };

  # Set TERMINAL environment variable when a terminal is configured
  config = mkIf (terminal.default != null) {
    home.sessionVariables = {
      TERMINAL = "${terminal.default}";
    };
  };
}
