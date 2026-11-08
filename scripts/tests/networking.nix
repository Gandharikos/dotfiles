# Evaluation only: no services, credentials, routes or sysctls are changed.
let
  flake = builtins.getFlake ("git+file://" + toString ../..);
  inherit (flake.inputs.nixpkgs) lib;
  inherit (lib) types;
  systems = flake.nixosConfigurations;
  ymir = systems.ymir.config;
  evaluate =
    extra:
    (lib.evalModules {
      modules = [
        {
          options = {
            boot.kernelModules = lib.mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            boot.kernel.sysctl = lib.mkOption {
              type = types.attrsOf types.anything;
              default = { };
            };
          };
        }
        ../../modules/nixos/networking/tuning.nix
        extra
      ];
    }).config;
  tuned = values: evaluate { dot.networking.tuning = values; };
  defaults = tuned { };
  bbr = tuned { congestionControl = "bbr"; };
  fq = tuned { defaultQdisc = "fq"; };
  probing = tuned { mtuProbing = 1; };
  disabledProbing = tuned { mtuProbing = 0; };
  combined = tuned {
    congestionControl = "bbr";
    defaultQdisc = "fq";
    mtuProbing = 1;
  };
  inherited = evaluate {
    boot.kernelModules = [ "dummy" ];
    boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "cubic";
  };
  rejects = values: !(builtins.tryEval (builtins.deepSeq (tuned values).boot true)).success;
  networkdOverride =
    (systems.ymir.extendModules {
      modules = [ { networking.useNetworkd = false; } ];
    }).config;
  managerOverride =
    (systems.ymir.extendModules {
      modules = [ { networking.networkmanager.enable = false; } ];
    }).config;
  snapshot =
    host:
    let
      c = host.config;
    in
    {
      type = c.dot.device.type or "installer";
      networkManager = { inherit (c.networking.networkmanager) enable dns unmanaged; };
      inherit (c.networking)
        useNetworkd
        useDHCP
        enableIPv6
        nameservers
        ;
      networkd = {
        inherit (c.systemd.network) enable;
        global = c.systemd.network.config.networkConfig;
        networks = lib.mapAttrs (_: n: {
          inherit (n)
            matchConfig
            networkConfig
            linkConfig
            DHCP
            ;
        }) c.systemd.network.networks;
        waitOnline = c.systemd.network.wait-online.enable;
      };
      resolved = { inherit (c.services.resolved) enable settings; };
      reversePath = c.networking.firewall.checkReversePath;
      networkSysctls = lib.filterAttrs (name: _: lib.hasPrefix "net." name) c.boot.kernel.sysctl;
      inherit (c.boot) kernelModules;
      iwd = {
        inherit (c.networking.wireless.iwd) enable;
        networkConfiguration =
          c.networking.wireless.iwd.settings.General.EnableNetworkConfiguration or null;
        nmBackend = c.networking.networkmanager.wifi.backend;
      };
      nftables = c.networking.nftables.enable;
    };
  ownership = {
    athena = {
      nm = true;
      networkd = true;
    };
    installer = {
      nm = true;
      networkd = false;
    };
    loki = {
      nm = true;
      networkd = true;
    };
    mimir = {
      nm = false;
      networkd = true;
    };
    nidhogg = {
      nm = false;
      networkd = false;
    };
    sigurd = {
      nm = true;
      networkd = true;
    };
    ymir = {
      nm = true;
      networkd = true;
    };
  };
in
{
  # Compare before/after privately; this is declared configuration, not runtime health.
  hosts = lib.mapAttrs (_: snapshot) systems;
  checks = {
    defaultsUntouched =
      assert defaults.boot.kernel.sysctl == { } && defaults.boot.kernelModules == [ ];
      assert inherited.boot.kernel.sysctl == { "net.ipv4.tcp_congestion_control" = "cubic"; };
      assert inherited.boot.kernelModules == [ "dummy" ];
      true;
    independentOptions =
      assert bbr.boot.kernel.sysctl == { "net.ipv4.tcp_congestion_control" = "bbr"; };
      assert bbr.boot.kernelModules == [ "tcp_bbr" ];
      assert fq.boot.kernel.sysctl == { "net.core.default_qdisc" = "fq"; };
      assert fq.boot.kernelModules == [ "sch_fq" ];
      assert probing.boot.kernel.sysctl == { "net.ipv4.tcp_mtu_probing" = 1; };
      assert probing.boot.kernelModules == [ ];
      assert disabledProbing.boot.kernel.sysctl == { "net.ipv4.tcp_mtu_probing" = 0; };
      assert
        combined.boot.kernel.sysctl == {
          "net.ipv4.tcp_congestion_control" = "bbr";
          "net.core.default_qdisc" = "fq";
          "net.ipv4.tcp_mtu_probing" = 1;
        };
      assert
        combined.boot.kernelModules == [
          "tcp_bbr"
          "sch_fq"
        ];
      true;
    explicitAlternatives =
      assert lib.all
        (
          name:
          let
            c = tuned { congestionControl = name; };
          in
          c.boot.kernel.sysctl == { "net.ipv4.tcp_congestion_control" = name; } && c.boot.kernelModules == [ ]
        )
        [
          "reno"
          "cubic"
        ];
      assert lib.all
        (
          name:
          let
            c = tuned { defaultQdisc = name; };
          in
          c.boot.kernel.sysctl == {
            "net.core.default_qdisc" = name;
          }
          && c.boot.kernelModules == [ "sch_${name}" ]
        )
        [
          "fq_codel"
          "cake"
        ];
      assert (tuned { mtuProbing = 2; }).boot.kernel.sysctl == { "net.ipv4.tcp_mtu_probing" = 2; };
      true;
    rejectsInvalidOptions =
      assert rejects { congestionControl = "unknown"; };
      assert rejects { defaultQdisc = "unknown"; };
      assert rejects { mtuProbing = 3; };
      true;
    managersOverridable =
      assert !networkdOverride.networking.useNetworkd;
      assert !managerOverride.networking.networkmanager.enable;
      true;
    hostOwnershipPreserved =
      assert lib.all (
        name:
        let
          c = systems.${name}.config;
          expected = ownership.${name};
        in
        c.networking.networkmanager.enable == expected.nm && c.systemd.network.enable == expected.networkd
      ) (builtins.attrNames ownership);
      true;
    nftablesMigrationPreservesFirewallPolicy =
      assert lib.all (
        name:
        let
          host = systems.${name};
          c = host.config;
          legacy =
            (host.extendModules {
              modules = [ { networking.nftables.enable = lib.mkForce false; } ];
            }).config;
          policy = lib.getAttrs [
            "enable"
            "allowPing"
            "checkReversePath"
            "logReversePathDrops"
            "logRefusedConnections"
            "filterForward"
            "allowedTCPPorts"
            "allowedUDPPorts"
            "allowedTCPPortRanges"
            "allowedUDPPortRanges"
            "trustedInterfaces"
          ];
        in
        c.networking.nftables.enable == !(builtins.elem name [
          "installer"
          "nidhogg"
        ])
        && !c.networking.nftables.flushRuleset
        && policy c.networking.firewall == policy legacy.networking.firewall
      ) (builtins.attrNames ownership);
      true;
    hostsRemainUntuned =
      assert lib.all (
        host:
        let
          tuning = host.config.dot.networking.tuning or null;
        in
        tuning == null
        || (tuning.congestionControl == null && tuning.defaultQdisc == null && tuning.mtuProbing == null)
      ) (builtins.attrValues systems);
      true;
    sharedResolvedDisablesLlmnr =
      assert lib.all (
        host:
        !(host.options ? dot.device.ethernetDevices)
        || (host.config.services.resolved.settings.Resolve.LLMNR or null) == false
      ) (builtins.attrValues systems);
      true;
    iwdLeavesIpConfigurationToNetworkManager =
      assert lib.all (
        host:
        let
          c = host.config;
        in
        !c.networking.wireless.iwd.enable
        || (
          c.networking.networkmanager.enable
          && c.networking.networkmanager.wifi.backend == "iwd"
          && (c.networking.wireless.iwd.settings.General.EnableNetworkConfiguration or null) == false
        )
      ) (builtins.attrValues systems);
      assert
        (managerOverride.networking.wireless.iwd.settings.General.EnableNetworkConfiguration or null)
        == false;
      true;
    wslHostFileOwnedByNixos =
      assert systems.nidhogg.config.wsl.wslConf.network.generateHosts == false;
      assert !(systems.nidhogg.config.wsl.wslConf.network ? gnerateHosts);
      true;
    ymirDnsAndBypassesPreserved =
      assert ymir.services.resolved.settings.Resolve.DNS == [ "127.0.0.1:1053" ];
      assert ymir.services.resolved.settings.Resolve.DNSSEC == false;
      assert ymir.services.resolved.settings.Resolve.FallbackDNS == [ ];
      assert builtins.elem "interface-name:sb-tun" ymir.networking.networkmanager.unmanaged;
      assert builtins.elem "interface-name:tailscale*" ymir.networking.networkmanager.unmanaged;
      assert ymir.systemd.network.networks."50-tailscale".linkConfig.Unmanaged;
      assert ymir.dot.networking.tailscale.exitNode == "";
      assert !ymir.dot.networking.tailscale.acceptDns && !ymir.dot.networking.tailscale.acceptRoutes;
      assert !ymir.dot.networking.proxy.dae.enable;
      assert lib.all (name: !(builtins.hasAttr name ymir.systemd.network.config.networkConfig)) [
        "ManageForeignRoutingPolicyRules"
        "ManageForeignRoutes"
        "ManageForeignNextHops"
      ];
      true;
  };
}
