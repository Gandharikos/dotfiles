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
  tyrGhostty =
    let
      tyr = flake.darwinConfigurations.tyr;
      home = tyr.config.home-manager.users.johnson;
      inherit (home.my.gui) terminal;
    in
    assert terminal.default == "ghostty";
    assert home.programs.ghostty.package == null;
    assert
      terminal.command == [
        "/usr/bin/open"
        "-n"
        "-b"
        "com.mitchellh.ghostty"
      ];
    assert
      home.programs.aerospace.settings.mode.main.binding."${home.my.gui.desktop.modKey}-enter"
      == "exec-and-forget ${terminal.exec}";
    true;
  linuxGhostty =
    let
      linux = flake.nixosConfigurations.ymir.extendModules {
        modules = [
          {
            home-manager.users.johnson.my.gui.terminal.default = lib.mkForce "ghostty";
          }
        ];
      };
      terminal = linux.config.home-manager.users.johnson.my.gui.terminal;
    in
    assert builtins.elem (lib.getExe linux.pkgs.ghostty) terminal.command;
    assert lib.last terminal.command == "+new-window";
    assert !(builtins.elem "/usr/bin/open" terminal.command);
    true;
  defaultXdg = check { } ".config/aerospace/aerospace.toml";
  customXdg = check {
    xdg.configHome = lib.mkForce "/Users/johnson/settings";
  } "settings/aerospace/aerospace.toml";
  withoutXdg = check {
    xdg.enable = lib.mkForce false;
  } ".aerospace.toml";
}
