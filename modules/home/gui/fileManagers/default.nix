{
  lib,
  pkgs,
  config,
  osClass,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum nullOr str;
  inherit (lib.meta) getExe;
  inherit (lib.my) withUWSM isHyprland;
  inherit (config.my.gui) fileManager;
in {
  imports = lib.my.scanPaths ./.;

  options.my.gui.fileManager = {
    default = mkOption {
      type = nullOr (enum [
        "cosmic-files"
        "dolphin"
        "nemo"
      ]);
      default =
        if config.my.gui.enable && osClass == "nixos"
        then "cosmic-files"
        else null;
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
        if isHyprland config
        then withUWSM pkgs fileManager.default
        else getExe (builtins.getAttr fileManager.default pkgs);
      description = ''
        The command to use for the file manager. This is used by the
        `my.gui.fileManager` module to determine which command to run.
      '';
    };
  };

  config = mkIf (fileManager.default != null) {
    home.packages = [
      (builtins.getAttr fileManager.default pkgs)
    ];
    home.sessionVariables = {FILEMANAGER = "${fileManager.default}";};
  };
}
