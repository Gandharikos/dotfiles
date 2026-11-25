# Evaluation/build only: no client or running network is changed.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  inherit (flake.inputs.nixpkgs) lib;
  host = flake.nixosConfigurations.heimdall;
  c = host.config;
  tyrStartup =
    flake.darwinConfigurations.tyr.config.launchd.daemons.tailscale-up.serviceConfig.ProgramArguments;
  dae =
    (host.extendModules {
      modules = [
        {
          dot.networking.proxy.backend = lib.mkForce "dae";
        }
      ];
    }).config;
in
{
  system = c.system.build.toplevel;
  unit = c.systemd.units."heimdall-pilot-tailnet.service".unit;
  checks =
    assert lib.all (a: a.assertion) c.assertions;
    assert c.boot.kernel.sysctl."net.ipv4.ip_forward" == 1;
    assert c.systemd.network.networks."10-management".networkConfig.IPv4Forwarding;
    assert c.boot.kernel.sysctl."net.ipv6.conf.all.forwarding";
    assert c.services.tailscale.useRoutingFeatures == "both";
    assert c.networking.firewall.checkReversePath == "loose";
    assert c.boot.kernel.sysctl."net.ipv6.conf.default.forwarding" == 1;
    assert c.boot.kernel.sysctl."net.ipv6.conf.enp2s0.forwarding" == 0;
    assert !c.systemd.network.networks."10-management".networkConfig.IPv6Forwarding;
    assert c.dot.networking.tailscale.role == "exit-node";
    assert !c.dot.networking.proxy.profile.singBox.ipv4OnlyUplink;
    assert c.dot.networking.tailscale.exitNode == "";
    assert builtins.elem "--advertise-exit-node=true" c.services.tailscale.extraSetFlags;
    assert c.dot.networking.tailscale.advertiseRoutes == [ ];
    assert !(c.systemd.services ? heimdall-exit-route);
    assert !(c.networking.nftables.tables ? heimdall-exit);
    assert lib.all (
      route: (route.Table or null) != 2024
    ) c.systemd.network.networks."10-management".routes;
    assert lib.all (
      rule: (rule.Table or null) != 2024
    ) c.systemd.network.networks."10-management".routingPolicyRules;
    assert lib.hasInfix ''iifname "tailscale0" oifname "enp2s0" ip saddr 100.64.0.0/10''
      c.networking.firewall.extraForwardRules;
    assert lib.hasInfix "ip daddr != { 0.0.0.0/8, 10.0.0.0/8" c.networking.firewall.extraForwardRules;
    assert lib.any (
      path: lib.hasSuffix ":/etc/resolv.conf" path
    ) c.systemd.services.tailscaled.serviceConfig.BindReadOnlyPaths;
    assert !c.networking.nat.enable && !c.services.dnsmasq.enable;
    assert c.networking.firewall.filterForward;
    assert c.networking.firewall.trustedInterfaces == [ "lo" ];
    assert c.services.resolved.settings.Resolve.DNSStubListenerExtra == [ "192.168.8.2" ];
    assert lib.hasInfix ''iifname "enp2s0" ip saddr 192.168.8.0/24 oifname "sb-tun" counter accept''
      c.networking.firewall.extraForwardRules;
    assert lib.hasInfix ''iifname "enp2s0" ip saddr 192.168.8.0/24 ip daddr 192.168.8.2''
      c.networking.firewall.extraInputRules;
    assert !(lib.hasInfix "ether saddr" c.networking.firewall.extraInputRules);
    assert !(lib.hasInfix "ether saddr" c.networking.firewall.extraForwardRules);
    assert lib.hasInfix ''iifname "enp2s0" ip saddr 192.168.8.0/24 oifname != "sb-tun" counter drop''
      c.networking.nftables.tables.heimdall-pilot.content;
    assert lib.hasInfix ''iifname "enp2s0" meta nfproto ipv6 counter drop''
      c.networking.nftables.tables.heimdall-pilot.content;
    assert c.boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" == 0;
    assert c.boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" == 0;
    assert c.boot.kernel.sysctl."net.ipv4.conf.enp2s0.send_redirects" == 0;
    assert lib.hasInfix "priority -5" c.networking.nftables.tables.heimdall-pilot.content;
    assert lib.hasInfix ''oifname != "sb-tun" counter drop''
      c.networking.nftables.tables.heimdall-pilot.content;
    assert c.dot.networking.proxy.profile.tailnet.webUI.enable;
    assert lib.hasInfix "--https=443" c.systemd.services.sing-box-tailnet-webui.serviceConfig.ExecStart;
    assert lib.hasInfix "http://127.0.0.1:9090"
      c.systemd.services.sing-box-tailnet-webui.serviceConfig.ExecStart;
    assert !(builtins.elem 9090 c.networking.firewall.allowedTCPPorts);
    assert c.systemd.services.heimdall-pilot-tailnet.bindsTo == [ "sing-box.service" ];
    assert c.systemd.services.heimdall-pilot-tailnet.partOf == [ "sing-box.service" ];
    assert lib.any (
      rule:
      rule.From == "192.168.8.0/24"
      && rule.To == "100.64.0.0/10"
      && rule.IncomingInterface == "enp2s0"
      && rule.Priority == 5100
      && rule.Table == 2023
    ) c.systemd.network.networks."10-management".routingPolicyRules;
    assert builtins.length c.systemd.network.networks."10-management".routingPolicyRules == 1;
    assert dae.boot.kernel.sysctl."net.ipv4.ip_forward" == 1;
    assert dae.systemd.network.networks."10-management".networkConfig.IPv4Forwarding;
    assert dae.systemd.network.networks."10-management".routingPolicyRules == [ ];
    assert dae.dot.networking.tailscale.role == "exit-node";
    assert dae.boot.kernel.sysctl."net.ipv6.conf.all.forwarding";
    assert !(dae.systemd.services ? heimdall-exit-route);
    assert !(dae.networking.nftables.tables ? heimdall-exit);
    assert !(dae.systemd.services ? heimdall-pilot-tailnet);
    assert !(dae.networking.nftables.tables ? heimdall-pilot);
    assert builtins.length tyrStartup == 3;
    assert builtins.head tyrStartup == "/bin/sh";
    assert builtins.elemAt tyrStartup 1 == "-c";
    assert lib.hasPrefix "/bin/wait4path /nix/store/" (builtins.elemAt tyrStartup 2);
    assert lib.hasInfix " && exec /nix/store/" (builtins.elemAt tyrStartup 2);
    assert flake.darwinConfigurations.tyr.config.dot.networking.tailscale.role == "subnet-router";
    assert
      flake.darwinConfigurations.tyr.config.dot.networking.tailscale.advertiseRoutes
      == [ "192.168.1.0/24" ];
    assert !flake.darwinConfigurations.tyr.config.dot.networking.tailscale.acceptDns;
    assert flake.darwinConfigurations.tyr.config.networking.knownNetworkServices == [ ];
    assert !flake.darwinConfigurations.eir.config.dot.networking.tailscale.acceptDns;
    assert flake.darwinConfigurations.eir.config.networking.knownNetworkServices == [ ];
    true;
}
