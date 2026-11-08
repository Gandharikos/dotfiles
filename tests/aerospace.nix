# Pure evaluation: no activation or writes to the user home.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  host = flake.darwinConfigurations.eir;
  eirHome = host.config.home-manager.users.johnson;
  check =
    extraConfig: expectedTarget:
    let
      configured = host.extendModules {
        modules = [
          {
            dot.gui.enable = lib.mkForce true;
            dot.gui.desktop.default = lib.mkForce "aerospace";
            home-manager.users.johnson = extraConfig;
          }
        ];
      };
      home = configured.config.home-manager.users.johnson;
      files = lib.filter (file: file.enable && lib.hasSuffix "aerospace.toml" file.target) (
        lib.attrValues home.home.file
      );
      file = builtins.head files;
    in
    assert home.home.fileActivator == "putter";
    assert builtins.length files == 1;
    assert file.target == expectedTarget;
    assert !(lib.hasPrefix "/" file.target);
    assert file.source != null;
    assert file.onChange != "";
    assert home.launchd.agents.aerospace.enable;
    true;
in
{
  eirApplications =
    let
      inherit (eirHome.my.gui) terminal browser;
      settings = eirHome.programs.aerospace.settings;
      managedOnFirstWorkspace =
        appId:
        builtins.any (
          rule: rule."if".app-id == appId && rule.run == "move-node-to-workspace 1"
        ) settings.on-window-detected;
    in
    assert terminal.default == "rex";
    assert browser.default == "google-chrome";
    assert eirHome.programs.rex.enable;
    assert eirHome.home.sessionVariables.TERMINAL == builtins.head terminal.command;
    assert eirHome.home.sessionVariables.BROWSER == builtins.head browser.command;
    assert
      settings.mode.main.binding."${eirHome.my.gui.desktop.modKey}-enter"
      == "exec-and-forget ${terminal.exec}";
    assert managedOnFirstWorkspace "com.superlogical.rex";
    assert managedOnFirstWorkspace "com.google.Chrome";
    true;
  defaultXdg = check { } ".config/aerospace/aerospace.toml";
  customXdg = check {
    xdg.configHome = lib.mkForce "/Users/johnson/settings";
  } "settings/aerospace/aerospace.toml";
  withoutXdg = check {
    xdg.enable = lib.mkForce false;
  } ".aerospace.toml";
}
