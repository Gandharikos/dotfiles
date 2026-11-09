# Evaluation only: do not start, stop, or migrate the MicroVM.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  systems = flake.nixosConfigurations;
  loki = systems.loki.config;
  ymir = systems.ymir.config;
  ssh = ymir.home-manager.users.johnson.programs.ssh.settings;
  metadata = import ../hosts/loki/default.nix;
in
{
  lokiReplacesMimir =
    assert !(systems ? mimir);
    assert loki.networking.hostName == "loki";
    assert loki.dot.device.type == "vm";
    assert !(metadata.deployable or false);
    assert !(builtins.pathExists ../hosts/loki/hardware-configuration.nix);
    assert loki.sops.secrets == { };
    true;
  vmIdentityPreserved =
    assert loki.microvm.hypervisor == "qemu";
    assert loki.microvm.vcpu == 2 && loki.microvm.mem == 2560;
    assert loki.microvm.machineId == "356f873d-454c-4afc-bc92-a499bce5d4ed";
    assert loki.microvm.socket == null;
    assert
      map (i: { inherit (i) type id mac; }) loki.microvm.interfaces == [
        {
          type = "user";
          id = "loki";
          mac = "02:00:00:00:00:01";
        }
      ];
    assert builtins.length loki.microvm.forwardPorts == 1;
    assert
      (builtins.head loki.microvm.forwardPorts).host == {
        address = "127.0.0.1";
        port = 10022;
      };
    assert (builtins.head loki.microvm.forwardPorts).guest.port == 22;
    true;
  parentAndSshRenamed =
    assert ymir.microvm.vms ? loki;
    assert !(ymir.microvm.vms ? mimir);
    assert !ymir.microvm.vms.loki.autostart;
    assert ymir.microvm.vms.loki.evaluatedConfig.config.networking.hostName == "loki";
    assert ymir.systemd.services."microvm@loki".serviceConfig.ExecStop == "";
    assert !(ymir.systemd.services ? "microvm@mimir");
    assert ssh.loki.data.HostName == "localhost" && ssh.loki.data.Port == 10022;
    assert ssh.loki.data.User == "johnson";
    assert !(ssh ? mimir);
    true;
}
