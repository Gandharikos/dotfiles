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
    str
    listOf
    coercedTo
    ;
  inherit (lib.meta) getExe;
  inherit (lib.strings) escapeShellArgs hasInfix;
  inherit (lib.dot) withUWSMArgs;
  inherit (config.dot.gui) desktop fileManager;
  inherit (config.dot) gui;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  enable = gui.enable && isLinux;
  commandType = coercedTo str (
    value:
    if hasInfix " " value then
      throw ''
        `dot.gui.fileManager.command` accepts either an argv list or a single
        program path. Use a list for commands with arguments.
      ''
    else
      [ value ]
  ) (listOf str);
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.gui.fileManager = {
    default = mkOption {
      type = enum [
        "cosmic-files"
        "dolphin"
        "nemo"
      ];
      default = "cosmic-files";
      description = "The file manager to use";
    };
    desktopId = mkOption {
      type = str;
      default = "${fileManager.default}.desktop";
      description = "Desktop entry id used for XDG mime associations.";
    };
    command = mkOption {
      type = commandType;
      default =
        if desktop.uwsm.enable then
          withUWSMArgs pkgs fileManager.default
        else
          [
            getExe
            (builtins.getAttr fileManager.default pkgs)
          ];
      description = ''
        The argv form of the file manager command. This is used by
        compositors like Niri that expect a program and its arguments
        as a list instead of a shell string.
      '';
    };

    exec = mkOption {
      type = str;
      default = escapeShellArgs fileManager.command;
      internal = true;
      readOnly = true;
      description = ''
        The shell-escaped file manager command derived from
        `dot.gui.fileManager.command`.
      '';
    };
  };

  config = mkIf enable {
    home.packages = [
      (builtins.getAttr fileManager.default pkgs)
    ];
    home.sessionVariables = {
      FILEMANAGER = "${fileManager.default}";
    };
  };
}
