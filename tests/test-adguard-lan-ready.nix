# Linux VM only: exercises the actual host gate, never production interfaces/secrets.
let
  f = builtins.getFlake ("git+file://" + toString ../.);
  host = f.nixosConfigurations.heimdall;
  inherit (host) pkgs;
  inherit (pkgs) lib;
  gate = builtins.head host.config.systemd.services.adguardhome.serviceConfig.ExecStartPre;
  shortGate = lib.replaceStrings [ "--timeout=60" ] [ "--timeout=2" ] gate;
  # Keep the real DynamicUser, address-family, syscall and filesystem restrictions.
  sandbox = builtins.removeAttrs host.config.systemd.services.adguardhome.serviceConfig [
    "ExecStart"
    "ExecStartPre"
    "LoadCredential"
    "StateDirectory"
    "WorkingDirectory"
    "User"
    "Group"
    "Restart"
    "RestartSec"
  ];
  bindCheck = pkgs.writeText "check-lan-bind.py" ''
    import pathlib, socket, sys
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("192.168.8.2", 0))
        pathlib.Path("/run/" + sys.argv[1] + "/bound").touch()
  '';
  probe = name: command: {
    after = [ "systemd-networkd.service" ];
    serviceConfig = sandbox // {
      RuntimeDirectory = name;
      StateDirectory = name;
      WorkingDirectory = "/var/lib/${name}";
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = [ command ];
      ExecStart = "${pkgs.python3}/bin/python3 ${bindCheck} ${name}";
      TimeoutStartSec = 75;
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "adguard-lan-readiness";
  nodes.machine = {
    networking.useNetworkd = true;
    networking.useDHCP = false;
    systemd.network.wait-online.enable = false;
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp2s0";
      addresses = [
        {
          Address = "192.168.8.2/24";
          DuplicateAddressDetection = "ipv4";
        }
      ];
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = false;
      };
    };
    systemd.network.networks."20-ipv6-only" = {
      matchConfig.Name = "ipv6-only0";
      addresses = [
        {
          Address = "2001:db8::2/64";
          DuplicateAddressDetection = "none";
        }
      ];
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = false;
      };
    };
    systemd.services = {
      missing-lan = probe "missing-lan-bound" shortGate;
      ipv6-only = probe "ipv6-only-bound" (lib.replaceStrings [ "enp2s0" ] [ "ipv6-only0" ] shortGate);
      delayed-lan = probe "delayed-lan-bound" gate;
      retry-lan = lib.recursiveUpdate (probe "retry-lan-bound" shortGate) {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 1;
        };
      };
    };
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("systemd-networkd.service")

    with subtest("absent interface times out without running the listener"):
        machine.fail("ip link show enp2s0")
        machine.fail("systemctl start missing-lan.service")
        machine.succeed("test ! -e /run/missing-lan-bound/bound")
        machine.succeed("systemctl reset-failed missing-lan.service")

    with subtest("IPv6 alone does not satisfy the IPv4 gate"):
        machine.succeed("ip link add ipv6-only0 type dummy; ip link set ipv6-only0 up")
        machine.wait_until_succeeds("networkctl --no-pager status ipv6-only0 | grep 'routable (configured)'")
        machine.fail("systemctl start ipv6-only.service")
        machine.succeed("test ! -e /run/ipv6-only-bound/bound")
        machine.succeed("systemctl reset-failed ipv6-only.service")

    with subtest("delayed LAN configuration permits bind only after readiness"):
        machine.succeed("systemctl start --no-block delayed-lan.service")
        machine.wait_until_succeeds("test $(systemctl show delayed-lan -p ActiveState --value) = activating")
        machine.succeed("test ! -e /run/delayed-lan-bound/bound")
        machine.succeed("ip link add enp2s0 type dummy; ip link set enp2s0 up")
        machine.wait_for_unit("delayed-lan.service")
        machine.succeed("test -e /run/delayed-lan-bound/bound")

    with subtest("failed readiness attempt can recover when the address arrives"):
        machine.succeed("ip link delete enp2s0")
        machine.succeed("systemctl start --no-block retry-lan.service")
        machine.wait_until_succeeds("test $(systemctl show retry-lan -p NRestarts --value) -ge 1")
        machine.succeed("test ! -e /run/retry-lan-bound/bound")
        machine.succeed("ip link add enp2s0 type dummy; ip link set enp2s0 up")
        machine.wait_for_unit("retry-lan.service")
        machine.succeed("test -e /run/retry-lan-bound/bound")
  '';
}
