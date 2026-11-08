{
  lib,
  pkgs,
  config,
  osConfig,
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
  inherit (lib.dot) uwsmAppArgs;
  inherit (config.my.gui) terminal;
  rexLauncher = pkgs.writeShellScript "rex-terminal" ''
    exec /usr/bin/open -b com.superlogical.rex "$@"
  '';
  terminalProgram =
    if terminal.default == "rex" then
      toString rexLauncher
    else
      getExe (builtins.getAttr terminal.default pkgs);
  terminalArgs = if terminal.default == "ghostty" then [ "+new-window" ] else [ ];
  commandType = coercedTo str (
    value:
    if hasInfix " " value then
      throw ''
        `dot.gui.terminal.command` accepts either an argv list or a single
        program path. Use a list for commands with arguments.
      ''
    else
      [ value ]
  ) (listOf str);
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.gui.terminal = {
    name = mkOption {
      type = nullOr str;
      default = null;
    };

    default = mkOption {
      type = nullOr (
        enum (
          [
            "wzeterm"
            "ghostty"
            "kitty"
            "warp"
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ "rex" ]
        )
      );
      default = if osConfig.dot.gui.enable then "ghostty" else null;
      description = "The terminal to use. On macOS, rex opens the separately installed Rex app.";
    };

    command = mkOption {
      type = commandType;
      default =
        if terminal.default == null then
          [ ]
        else if pkgs.stdenv.hostPlatform.isDarwin && terminal.default == "ghostty" then
          # macOS uses the Homebrew app; pkgs.ghostty pulls in GTK/Wayland dependencies.
          [
            "/usr/bin/open"
            "-n"
            "-b"
            "com.mitchellh.ghostty"
          ]
        else if osConfig.dot.gui.desktop.uwsm.enable then
          uwsmAppArgs pkgs terminalProgram terminalArgs
        else
          [ terminalProgram ] ++ terminalArgs;
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
        `dot.gui.terminal.command`.
      '';
    };

    size = mkOption {
      type = int;
      default = 12;
      description = ''
        The font size to use for the terminal. This is used by the
        `dot.gui.terminal` module to determine which font size to use.
      '';
    };

    font = mkOption {
      type = str;
      default = "JetBrainsMono Nerd Font Mono";
      description = ''
        The font to use for the terminal. This is used by the
        `dot.gui.terminal` module to determine which font to use.
      '';
    };

    padding = mkOption {
      type = int;
      default = 5;
      description = ''
        The padding to use for the terminal. This is used by the
        `dot.gui.terminal` module to determine which padding to use.
      '';
    };

    opacity = mkOption {
      type = float;
      default = 0.85;
      description = ''
        The opacity to use for the terminal. This is used by the
        `dot.gui.terminal` module to determine which opacity to use.
      '';
    };
  };

  # Set TERMINAL environment variable when a terminal is configured
  config = mkIf (terminal.default != null) {
    home.sessionVariables = {
      TERMINAL = if terminal.default == "rex" then toString rexLauncher else terminal.default;
    };
  };
}
