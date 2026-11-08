# Pure evaluation: no activation, GUI uninstallation or secret decryption.
let
  flake = builtins.getFlake ("git+file://" + toString ../..);
  lib = flake.inputs.nixpkgs.lib;
  linux = flake.nixosConfigurations.ymir;
  darwin = flake.darwinConfigurations.eir;
  darwinMihomo = darwin.extendModules {
    modules = [
      ({ lib, ... }: {
        dot.networking.proxy = {
          enable = lib.mkForce true;
          backend = lib.mkForce "mihomo";
        };
      })
    ];
  };
  checkBackends =
    host:
    let
      type = host.options.dot.networking.proxy.backend.type;
    in
    assert type.check "mihomo" && type.check "sing-box" && !type.check "clash-verge";
    assert !type.check "dae";
    assert !(host.options.dot.networking.proxy ? clashVerge);
    true;
  home = linux.config.home-manager.users.johnson;
  caskName = cask: if builtins.isString cask then cask else cask.name;
in
{
  backends = {
    nixos = checkBackends linux;
    darwin = checkBackends darwin;
  };
  noNixosDesktopIntegration =
    assert !linux.config.programs.clash-verge.enable;
    assert !(linux.config.users.groups ? clash-verge);
    assert !(home.home.activation ? clashVergeConfig);
    assert !(home.xdg.configFile ? "autostart/clash-verge.desktop");
    assert builtins.all (
      entry: !(lib.hasInfix "clash-verge" (if builtins.isString entry then entry else entry.directory))
    ) linux.config.dot.users.johnson.persistence.directories;
    true;
  darwinGuiAvailable =
    assert builtins.elem "clash-verge-rev" (map caskName darwin.config.homebrew.casks);
    true;
  darwinNativeMihomo =
    assert
      darwinMihomo.config.sops.secrets.proxy_config.path
      == "${darwinMihomo.config.dot.admin.homeDirectory}/.config/mihomo/config.yaml";
    assert builtins.any (
      package: lib.getName package == "mihomo"
    ) darwinMihomo.config.environment.systemPackages;
    assert builtins.all (entry: entry.assertion) darwinMihomo.config.assertions;
    true;
}
