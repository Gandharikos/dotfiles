# Evaluate/build only; this fixture never activates a system or decrypts credentials.
{
  backend ? "sing-box",
  hostname ? null,
  webUI ? true,
  mihomoPolicy ? null,
}:
let
  flake = builtins.getFlake ("git+file://" + toString ../..);
  lib = flake.inputs.nixpkgs.lib;
  fixture = flake.nixosConfigurations.ymir.extendModules {
    modules = [
      ({ lib, ... }: {
        networking.hostName = lib.mkForce "proxy-fixture";
        dot.networking.proxy = {
          backend = lib.mkForce backend;
          autoStart = lib.mkForce false;
          profile = {
            tailnet = {
              domain = lib.mkForce "fixture.ts.net";
              webUI = {
                enable = lib.mkForce webUI;
                httpsPort = 2443;
              };
            }
            // lib.optionalAttrs (hostname != null) { inherit hostname; };
            ports = {
              mixed = 27890;
              dns = 21053;
              controller = 29090;
            };
          }
          // lib.optionalAttrs (mihomoPolicy != null) { mihomo.policy = mihomoPolicy; };
        };
      })
    ];
  };
  conflictingPorts = fixture.extendModules {
    modules = [
      ({ lib, ... }: {
        dot.networking.proxy.profile.ports.dns = lib.mkForce 29090;
      })
    ];
  };
  cfg = fixture.config;
  native = backend == "sing-box";
  webUIService = "${backend}-tailnet-webui";
in
{
  unit = cfg.systemd.units."${backend}.service".unit;
  webUIUnit = cfg.systemd.units."${webUIService}.service".unit;
  program = builtins.head cfg.systemd.services.${backend}.serviceConfig.ExecStartPre;
  mihomoTemplate = if native then null else cfg.sops.templates."proxy-mihomo.yaml".content;
  checks =
    assert
      cfg.dot.networking.proxy.profile.tailnet.hostname == (
        if hostname != null then hostname else "proxy-fixture-${if native then "singbox" else "mihomo"}"
      );
    assert cfg.services.resolved.settings.Resolve.DNS == [ "127.0.0.1:21053" ];
    assert
      cfg.services.resolved.settings.Resolve.Domains == [
        "~."
        "fixture.ts.net"
      ];
    assert cfg.services.sing-box.enable == native;
    assert cfg.services.mihomo.enable == !native;
    assert !native || cfg.systemd.timers.sing-box-subscription.wantedBy == [ ];
    assert
      if webUI then
        cfg.systemd.services.${webUIService}.wantedBy == [ ]
        && builtins.elem "${backend}.service" cfg.systemd.services.${webUIService}.after
        && cfg.systemd.services.${webUIService}.requires == [ "tailscaled.service" ]
        && cfg.systemd.services.${webUIService}.partOf == [ "tailscaled.service" ]
        && lib.hasInfix "--https=2443" cfg.systemd.services.${webUIService}.serviceConfig.ExecStart
        &&
          lib.hasInfix "http://127.0.0.1:29090"
            cfg.systemd.services.${webUIService}.serviceConfig.ExecStart
        && lib.hasInfix "--https=2443" cfg.systemd.services.${webUIService}.serviceConfig.ExecStop
      else
        !(builtins.hasAttr webUIService cfg.systemd.services);
    assert
      !(builtins.hasAttr "${if native then "mihomo" else "sing-box"}-tailnet-webui" cfg.systemd.services);
    assert
      native
      || (
        lib.hasInfix cfg.sops.placeholder.mihomo_subscription_url
          cfg.sops.templates."proxy-mihomo.yaml".content
        &&
          lib.hasInfix cfg.sops.placeholder.mihomo_controller_secret
            cfg.sops.templates."proxy-mihomo.yaml".content
        && !(lib.hasInfix "__SUBSCRIPTION_URL__" cfg.sops.templates."proxy-mihomo.yaml".content)
        && !(lib.hasInfix "__CONTROLLER_SECRET__" cfg.sops.templates."proxy-mihomo.yaml".content)
      );
    assert builtins.all (entry: entry.assertion) cfg.assertions;
    assert builtins.any (
      entry:
      !entry.assertion
      && entry.message == "The shared proxy profile requires distinct mixed, DNS and controller ports."
    ) conflictingPorts.config.assertions;
    true;
}
