# Evaluation/build only: never activate interception or decrypt credentials.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  fixture = flake.nixosConfigurations.heimdall.extendModules {
    modules = [
      {
        dot.networking.proxy = {
          enable = true;
          backend = lib.mkForce "dae";
          autoStart = lib.mkForce false;
          profile = {
            enable = true;
            secretsFile = "${flake}/secrets/services/proxy.yml";
            tailnet.domain = lib.mkForce "fixture.ts.net";
            ports.dns = 21053;
          };
        };
      }
    ];
  };
  cfg = fixture.config;
  invalidWebUI = fixture.extendModules {
    modules = [ { dot.networking.proxy.profile.tailnet.webUI.enable = true; } ];
  };
in
{
  unit = cfg.systemd.units."dae.service".unit;
  prepareUnit = cfg.systemd.units."dae-config.service".unit;
  system = cfg.system.build.toplevel;
  checks =
    assert cfg.services.dae.enable;
    assert !cfg.services.sing-box.enable && !cfg.services.mihomo.enable;
    assert cfg.services.dae.configFile == "/run/dae/config.dae";
    assert cfg.systemd.services.dae.wantedBy == [ ];
    assert builtins.elem "dae-config.service" cfg.systemd.services.dae.requires;
    assert builtins.elem "dae-config.service" cfg.systemd.services.dae.after;
    assert cfg.systemd.services.dae-config.serviceConfig.RuntimeDirectoryMode == "0700";
    assert cfg.sops.secrets.dae_subscription_nodes.key == "subscription_nodes";
    assert cfg.services.resolved.settings.Resolve.DNS == [ "127.0.0.1:21053" ];
    assert !(builtins.elem "interface-name:mihomo" cfg.networking.networkmanager.unmanaged);
    assert !(cfg.systemd.services ? dae-tailnet-webui);
    assert !cfg.services.dae.openFirewall.enable;
    assert !cfg.services.dnsmasq.enable;
    assert cfg.boot.kernel.sysctl."net.ipv4.ip_forward" == 0;
    assert builtins.all (a: a.assertion) cfg.assertions;
    assert builtins.any (
      a: !a.assertion && lib.hasInfix "dae has no Clash controller" a.message
    ) invalidWebUI.config.assertions;
    true;
}
