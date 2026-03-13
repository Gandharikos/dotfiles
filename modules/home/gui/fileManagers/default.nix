{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum str;
  inherit (lib.meta) getExe;
  inherit (lib.my) withUWSM;
  inherit (config.my.gui) desktop fileManager;
  inherit (config.my) gui;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  enable = gui.enable && isLinux;
in {
  imports = lib.my.scanPaths ./.;

  options.my.gui.fileManager = {
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
    exec = mkOption {
      type = str;
      default =
        if desktop.uwsm.enable
        then withUWSM pkgs fileManager.default
        else getExe (builtins.getAttr fileManager.default pkgs);
      description = ''
        The command to use for the file manager. This is used by the
        `my.gui.fileManager` module to determine which command to run.
      '';
    };
  };

  config = mkIf enable {
    home.packages = [
      (builtins.getAttr fileManager.default pkgs)
    ];
    home.sessionVariables = {FILEMANAGER = "${fileManager.default}";};
  };
}
