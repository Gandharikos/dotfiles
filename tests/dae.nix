# Pure evaluation only: no dae process, kernel hooks or secret files are created.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  host = flake.nixosConfigurations.ymir;
  fixture =
    {
      enable ? true,
      autoStart ? null,
      configFile ? "/run/secrets/dae-config",
      mainEnable ? true,
      mainAutoStart ? true,
      backend ? "sing-box",
      extra ? { },
    }:
    (host.extendModules {
      modules = [
        ({ lib, ... }: {
          dot.networking.proxy = {
            enable = lib.mkForce mainEnable;
            backend = lib.mkForce backend;
            autoStart = lib.mkForce mainAutoStart;
            profile.enable = lib.mkForce mainEnable;
            dae = {
              inherit enable configFile;
            }
            // lib.optionalAttrs (autoStart != null) { inherit autoStart; };
          };
        })
        extra
      ];
    }).config;
  singBox = fixture { };
  mihomo = fixture { backend = "mihomo"; };
  standalone = fixture { mainEnable = false; };
  automatic = fixture {
    autoStart = true;
    mainAutoStart = false;
  };
  disabled = fixture {
    enable = false;
    configFile = null;
  };
  missing = fixture { configFile = null; };
  plaintext = fixture { extra.services.dae.config = "global {}"; };
  checkPair =
    backend: cfg:
    assert cfg.services.dae.enable;
    assert cfg.services.sing-box.enable == (backend == "sing-box");
    assert cfg.services.mihomo.enable == (backend == "mihomo");
    assert cfg.dot.networking.proxy.profile.enable;
    assert cfg.services.resolved.settings.Resolve == host.config.services.resolved.settings.Resolve;
    assert cfg.networking.nameservers == host.config.networking.nameservers;
    assert builtins.all (entry: entry.assertion) cfg.assertions;
    true;
  rejects =
    prefix: cfg:
    assert builtins.any (entry: !entry.assertion && lib.hasPrefix prefix entry.message) cfg.assertions;
    true;
in
{
  defaultOff =
    assert !host.config.dot.networking.proxy.dae.enable;
    assert !host.config.dot.networking.proxy.dae.autoStart;
    assert !host.config.services.dae.enable;
    assert !(host.config.systemd.services ? dae);
    assert
      !(builtins.any (package: lib.getName package == "dae") host.config.environment.systemPackages);
    assert !disabled.services.dae.enable && disabled.services.sing-box.enable;
    true;
  withSingBox = checkPair "sing-box" singBox;
  withMihomo = checkPair "mihomo" mihomo;
  independentEnable =
    assert
      standalone.services.dae.enable
      && !standalone.services.mihomo.enable
      && !standalone.services.sing-box.enable;
    assert builtins.elem "1.1.1.1" standalone.networking.nameservers;
    assert !(builtins.elem "127.0.0.1:1053" (standalone.services.resolved.settings.Resolve.DNS or [ ]));
    assert builtins.all (entry: entry.assertion) standalone.assertions;
    true;
  independentAutoStart =
    assert singBox.dot.networking.proxy.autoStart;
    assert singBox.systemd.services.dae.wantedBy == [ ];
    assert automatic.systemd.services.dae.wantedBy == [ "multi-user.target" ];
    assert automatic.systemd.services.sing-box.wantedBy == [ ];
    true;
  privateConfig =
    assert singBox.services.dae.config == null;
    assert builtins.elem "config.dae:/run/secrets/dae-config"
      singBox.systemd.services.dae.serviceConfig.LoadCredential;
    assert !singBox.services.dae.openFirewall.enable;
    true;
  rejectsMissingConfig = rejects "Enabling dae requires" missing;
  rejectsPlaintextStoreConfig = rejects "Use dae.configFile instead" plaintext;
}
