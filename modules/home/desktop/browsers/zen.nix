{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lib.my) withUWSM' isHyprland;
  cfg = config.my.desktop.apps.zen;
  zenPkg = inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.beta;
in {
  imports = [inputs.zen.homeModules.beta];

  options.my.desktop.apps.zen = {
    enable =
      mkEnableOption "zen browser"
      // {
        default = config.my.browser.default == "zen";
      };
  };

  config = mkIf cfg.enable {
    my.desktop.apps.firefox.enable = true;
    programs.zen-browser = {
      enable = true;
      nativeMessagingHosts = [pkgs.firefoxpwa];
      inherit (config.programs.firefox) policies;
      profiles.default = {
        isDefault = true;
        inherit (config.programs.firefox.profiles.default) userContent;
        settings =
          config.programs.firefox.profiles.default.settings
          // {
            # "zen.workspaces.natural-scroll" = true;
            "zen.view.compact.hide-tabbar" = true;
            # "zen.view.compact.animate-sidebar" = false;
            "zen.tabs.show-newtab-vertical" = false;
            "zen.theme.accent-color" = "#8aadf4";
            "zen.urlbar.behavior" = "float";
            "zen.view.compact.enable-at-startup" = true;
            "zen.view.compact.hide-toolbar" = true;
            "zen.view.compact.toolbar-flash-popup" = true;
            "zen.view.show-newtab-button-top" = false;
            "zen.view.window.scheme" = 0;
            "zen.welcome-screen.seen" = true;
            "zen.workspaces.continue-where-left-off" = true;
          };
        search = {
          force = true;
          default = "google";
          inherit (config.programs.firefox.profiles.default.search) engines;
        };
      };
    };
    my.browser.exec =
      if isHyprland config
      then withUWSM' pkgs zenPkg "zen"
      else (getExe' zenPkg "zen");
    home.persistence = {
      "/persist".directories = [".zen" ".cache/zen"];
    };
  };
}
