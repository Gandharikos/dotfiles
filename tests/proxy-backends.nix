# Pure evaluation: no activation, GUI uninstallation or secret decryption.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  linux = flake.nixosConfigurations.ymir;
  darwin = flake.darwinConfigurations.eir;
  darwinMihomo = darwin.extendModules {
    modules = [
      ({ lib, ... }: {
        dot.networking.proxy = {
          enable = lib.mkForce true;
          backend = lib.mkForce "mihomo";
          mihomo.configFile = "${darwin.config.dot.admin.homeDirectory}/.config/mihomo/config.yaml";
        };
      })
    ];
  };
  darwinSingBox = darwin.extendModules {
    modules = [
      {
        dot.networking.proxy = {
          enable = true;
          backend = "sing-box";
          singBox.configFile = "${darwin.config.dot.admin.homeDirectory}/.config/sing-box/config.json";
        };
      }
    ];
  };
  linuxDae = linux.extendModules {
    modules = [
      {
        dot.networking.proxy = {
          enable = lib.mkForce true;
          backend = lib.mkForce "dae";
          profile.enable = lib.mkForce false;
          autoStart = lib.mkForce false;
          dae.configFile = "/run/dae/config.dae";
        };
      }
    ];
  };
  linuxDaeAuto = linuxDae.extendModules {
    modules = [ { dot.networking.proxy.autoStart = lib.mkOverride 40 true; } ];
  };
  linuxDaeMissing = linuxDae.extendModules {
    modules = [ { dot.networking.proxy.dae.configFile = lib.mkForce null; } ];
  };
  missingConfig =
    backend:
    darwin.extendModules {
      modules = [
        {
          dot.networking.proxy = {
            enable = true;
            inherit backend;
          };
        }
      ];
    };
  checkBackends =
    host:
    let
      type = host.options.dot.networking.proxy.backend.type;
    in
    assert type.check "mihomo" && type.check "sing-box" && !type.check "clash-verge";
    assert type.check "dae" == host.pkgs.stdenv.hostPlatform.isLinux;
    assert (host.options.dot.networking.proxy ? dae) == host.pkgs.stdenv.hostPlatform.isLinux;
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
  nixosDae =
    let
      c = linuxDae.config;
    in
    assert c.services.dae.enable;
    assert c.services.dae.configFile == "/run/dae/config.dae";
    assert !c.services.dae.openFirewall.enable;
    assert !c.services.mihomo.enable && !c.services.sing-box.enable;
    assert c.systemd.services.dae.wantedBy == [ ];
    assert builtins.elem "multi-user.target" linuxDaeAuto.config.systemd.services.dae.wantedBy;
    assert builtins.all (entry: entry.assertion) c.assertions;
    assert builtins.any (
      entry: !entry.assertion && lib.hasInfix "dae.configFile" entry.message
    ) linuxDaeMissing.config.assertions;
    true;
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
      darwinMihomo.config.dot.networking.proxy.mihomo.configFile
      == "${darwinMihomo.config.dot.admin.homeDirectory}/.config/mihomo/config.yaml";
    assert !(darwinMihomo.config.sops.secrets ? proxy_config);
    assert builtins.any (
      package: lib.getName package == "mihomo"
    ) darwinMihomo.config.environment.systemPackages;
    assert builtins.all (entry: entry.assertion) darwinMihomo.config.assertions;
    true;
  darwinNativeSingBox =
    assert !(darwinSingBox.config.sops.secrets ? proxy_source_config);
    assert
      !(lib.hasInfix "generate-sing-box-config" darwinSingBox.config.system.activationScripts.postActivation.text);
    assert builtins.all (entry: entry.assertion) darwinSingBox.config.assertions;
    true;
  missingConfigRejected =
    assert lib.all
      (
        backend:
        lib.any (
          entry: !entry.assertion && lib.hasInfix "no legacy secret" entry.message
        ) (missingConfig backend).config.assertions
      )
      [
        "mihomo"
        "sing-box"
      ];
    true;
}
