{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [ inputs.microvm.nixosModules.host ];

  microvm.vms.loki = {
    evaluatedConfig = self.nixosConfigurations.loki;
    autostart = false;
    restartIfChanged = true;
  };

  # The guest is stateless, so stop QEMU directly instead of waiting for QMP.
  systemd.services."microvm@loki".serviceConfig.ExecStop = lib.mkForce "";
}
