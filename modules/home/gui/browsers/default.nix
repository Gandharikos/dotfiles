{
  lib,
  pkgs,
  config,
  osClass,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (lib.my) withUWSM;
  inherit (lib.types) enum nullOr str;
  inherit (lib.my) scanPaths;
  inherit (config.my.gui) browser desktop;
in {
  imports = scanPaths ./.;

  options.my.gui.browser = {
    default = mkOption {
      type = nullOr (enum [
        "zen"
        "google-chrome"
        "firefox"
      ]);
      default =
        if config.my.gui.enable && osClass == "nixos"
        then "zen"
        else null;
      description = "The browser to use";
    };
    desktopId = mkOption {
      type = str;
      default = "${browser.default}.desktop";
      description = "Desktop entry id used for XDG mime associations.";
    };
    exec = mkOption {
      type = str;
      default =
        if desktop.uwsm.enable
        then withUWSM pkgs browser.default
        else getExe (builtins.getAttr browser.default pkgs);
      description = ''
        The command to use for the browser. This is used by the
        `my.browser` module to determine which command to run.
      '';
    };
  };

  config = mkIf (browser.default != null) {
    home.sessionVariables = {BROWSER = "${browser.default}";};
  };
}
