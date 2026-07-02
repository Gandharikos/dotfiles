{
  inputs,
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lib.dot) uwsmAppArgs;
  cfg = config.my.gui.apps.helium;
  enable = osConfig.dot.gui.enable && cfg.enable;
  heliumPkg = pkgs.helium;
in
{
  imports = [ inputs.helium-browser.homeModules.default ];

  options.my.gui.apps.helium = {
    enable = mkEnableOption "Helium browser" // {
      default = config.my.gui.browser.default == "helium";
    };
  };

  config = mkIf enable {
    my.gui.browser.desktopId = "helium.desktop";

    programs.helium = {
      enable = true;
      package = heliumPkg;
      flags = [
        "--ozone-platform-hint=auto"
      ];
      policies = {
        BrowserSignin = 0;
        PasswordManagerEnabled = false;
        SyncDisabled = true;
      };
    };

    my.gui.browser.command =
      if osConfig.dot.gui.desktop.uwsm.enable then
        uwsmAppArgs pkgs (getExe' heliumPkg "helium") [ ]
      else
        [ (getExe' heliumPkg "helium") ];
  };
}
