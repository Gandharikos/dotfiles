{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lib.dot) uwsmAppArgs;
  inherit (config.dot) gui;
  inherit (config.dot.gui) desktop;
  cfg = config.dot.gui.apps.zen;
  enable = gui.enable && cfg.enable;
  zenPkg = inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.beta;
in
{
  imports = [ inputs.zen.homeModules.beta ];

  options.dot.gui.apps.zen = {
    enable = mkEnableOption "zen browser" // {
      default = config.dot.gui.browser.default == "zen";
    };
  };

  config = mkIf enable {
    dot.gui.apps.firefox.enable = lib.mkDefault true;
    dot.gui.browser.desktopId = "org.mozilla.com.zen.browser.desktop";
    programs.zen-browser = {
      enable = true;
      nativeMessagingHosts = [ pkgs.firefoxpwa ];
      inherit (config.programs.firefox) policies;
      profiles.default = {
        isDefault = true;
        inherit (config.programs.firefox.profiles.default) userContent;
        settings = config.programs.firefox.profiles.default.settings // {
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
    dot.gui.browser.command =
      if desktop.uwsm.enable then
        uwsmAppArgs pkgs (getExe' zenPkg "zen") [ ]
      else
        [ (getExe' zenPkg "zen") ];
  };
}
