{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkForce mkIf;
  cfg = config.dot.profiles;
  enable = cfg.hetzner.enable || cfg.oracle.enable || cfg.upcloud.enable;
in
{
  config = mkIf enable {
    services = {
      qemuGuest.enable = true;
      smartd.enable = mkForce false;
    };

    systemd.services.qemu-guest-agent.path = [ pkgs.shadow ];

    boot = {
      growPartition = !config.boot.initrd.systemd.enable;
      kernelParams = [ "net.ifnames=0" ];
      kernel.sysctl = {
        "net.ipv4.ip_forward" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
      initrd = {
        availableKernelModules = [
          "9p"
          "9pnet_virtio"
          "ata_piix"
          "uhci_hcd"
          "virtio_blk"
          "virtio_mmio"
          "virtio_net"
          "virtio_pci"
          "virtio_scsi"
          "xen_blkfront"
        ]
        ++ lib.optionals (!cfg.oracle.enable) [ "vmw_pvscsi" ];
        kernelModules = [
          "nvme"
          "virtio_balloon"
          "virtio_console"
          "virtio_gpu"
          "virtio_rng"
        ];
        systemd.enable = true;
      };
      loader.grub = {
        device = mkForce "";
        efiSupport = mkForce false;
        useOSProber = mkForce false;
      };
    };
  };
}
