# Pure module tests: no activation, network access or secret decryption.
let
  f = builtins.getFlake ("git+file://" + toString ../.);
  lib = f.inputs.nixpkgs.lib;
  base = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs.self = f;
    modules = [ { system.stateVersion = "26.11"; } ];
  };
  disabled = base.extendModules { modules = [ ../modules/nixos/networking/adguardhome.nix ]; };
  enabled = disabled.extendModules {
    modules = [
      {
        dot.networking.adguardhome = {
          enable = true;
          usersFile = "/run/credentials/test-adguard-users.json";
          seedFile = builtins.toFile "adguard-test-seed" "0.0.0.0 ads.example\n";
        };
        services.adguardhome.settings = {
          http.address = "127.0.0.1:13000";
          dns = {
            bind_hosts = [ "127.0.0.1" ];
            port = 15353;
            upstream_dns = [ "9.9.9.9" ];
            bootstrap_dns = [ "9.9.9.9" ];
          };
          filters = [
            {
              id = 7;
              name = "fixture";
              url = "https://example.invalid/hosts";
              enabled = true;
            }
          ];
        };
      }
    ];
  };
  valid =
    c:
    lib.all (
      a:
      a.assertion
      || !(
        lib.hasPrefix "dot.networking.adguardhome" a.message || lib.hasPrefix "The AdGuard preset" a.message
      )
    ) c.assertions;
  rejected = module: !valid (enabled.extendModules { modules = [ module ]; }).config;
  c = enabled.config;
in
{
  unit = c.systemd.units."adguardhome.service".unit;
  checks = {
    disabledHasNoSideEffects =
      assert !disabled.config.dot.networking.adguardhome.enable;
      assert !disabled.config.services.adguardhome.enable;
      assert !(disabled.config.systemd.services ? adguardhome);
      assert
        disabled.config.networking.firewall.allowedTCPPorts
        == base.config.networking.firewall.allowedTCPPorts;
      assert disabled.config.networking.nftables.tables == base.config.networking.nftables.tables;
      assert disabled.config.services.resolved.enable == base.config.services.resolved.enable;
      true;
    standaloneWithoutProxyOrSops =
      assert valid c;
      assert c.services.adguardhome.enable;
      assert !c.services.adguardhome.allowDHCP && !c.services.adguardhome.openFirewall;
      assert !(c.services.adguardhome.settings ? users);
      assert !(c.services.adguardhome.settings.dns ? cache_enabled);
      assert c.services.adguardhome.settings.http.address == "127.0.0.1:13000";
      assert c.services.adguardhome.settings.dns.port == 15353;
      assert c.services.adguardhome.settings.dns.upstream_dns == [ "9.9.9.9" ];
      assert
        c.systemd.services.adguardhome.serviceConfig.LoadCredential
        == [ "users.json:/run/credentials/test-adguard-users.json" ];
      assert !(builtins.elem "sing-box.service" c.systemd.services.adguardhome.after);
      assert !(builtins.elem "sops-install-secrets.service" c.systemd.services.adguardhome.requires);
      assert !(c.systemd.services ? adguardhome-tailnet-webui);
      assert c.networking.nftables.tables == base.config.networking.nftables.tables;
      assert c.services.resolved.enable == base.config.services.resolved.enable;
      true;
    invalidInputsRejected =
      assert rejected { dot.networking.adguardhome.usersFile = lib.mkForce null; };
      assert rejected { dot.networking.adguardhome.usersFile = lib.mkForce "relative.json"; };
      assert rejected { dot.networking.adguardhome.usersFile = lib.mkForce "/nix/store/unsafe-secret"; };
      assert rejected { dot.networking.adguardhome.seedFile = lib.mkForce null; };
      assert rejected { services.adguardhome.settings.filters = lib.mkForce [ ]; };
      assert rejected { services.adguardhome.settings.filters = lib.mkForce [ "invalid" ]; };
      assert rejected {
        services.adguardhome.settings.filters = lib.mkForce [
          { id = 1; }
          { id = 2; }
        ];
      };
      assert rejected { services.adguardhome.settings.filters = lib.mkForce [ { id = 0; } ]; };
      assert rejected {
        services.adguardhome.settings.filters = lib.mkForce [ { name = "missing-id"; } ];
      };
      assert rejected { services.adguardhome.settings.http.address = lib.mkForce "0.0.0.0:13000"; };
      assert rejected { services.adguardhome.settings.dns.bind_hosts = lib.mkForce [ ]; };
      assert rejected { services.adguardhome.settings.dns.upstream_dns = lib.mkForce [ ]; };
      true;
  };
}
