{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dot.virtual.qemu;
  isIntel = config.dot.device.cpu == "intel";
  isAmd = config.dot.device.cpu == "amd";
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (lib.lists) optionals;
in
{
  options.dot.virtual.qemu = {
    enable = mkEnableOption "Enable qemu" // {
      default = config.dot.virtual.enable;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Need to add [File (in the menu bar) -> Add connection] when start for the first time
      virt-manager
      virt-viewer
      # QEMU/KVM(HostCpuOnly), provides:
      #   qemu-storage-daemon qemu-edid qemu-ga
      #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
      #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
      qemu_kvm
      # Install QEMU(other architectures), provides:
      #   ......
      #   qemu-loongarch64 qemu-system-loongarch64
      #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
      #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
      #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
      #   ......
      qemu
    ];

    # Keep Secure Boot firmware with Microsoft-enrolled keys in the system closure.
    system.extraDependencies = [ pkgs.OVMFFull.fd ];

    virtualisation = {
      kvmgt.enable = true;
      spiceUSBRedirection.enable = true;

      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          verbatimConfig = ''
            namespaces = []

            swtpm_user = "qemu-libvirtd"
            swtpm_group = "qemu-libvirtd"

            # Whether libvirt should dynamically change file ownership
            dynamic_ownership = 0
          '';
        };

        onBoot = "ignore";
        onShutdown = "shutdown";
      };
    };

    systemd.tmpfiles.settings."10-swtpm-localca"."/var/lib/swtpm-localca".d = {
      user = "qemu-libvirtd";
      group = "qemu-libvirtd";
      mode = "0700";
    };

    # This allows libvirt to use pulseaudio socket
    # which is useful for virt-manager. May be just placebo, but I think
    # I have been experiencing better latency under emulation.
    services.pulseaudio.extraConfig = ''
      load-module module-native-protocol-unix auth-group=qemu-libvirtd socket=/tmp/pulse-socket
    '';

    # Additional kernel modules that may be needed by libvirt
    boot.kernelModules = [
      "vfio-pci"
    ]
    ++ optionals isAmd [ "kvm-amd" ]
    ++ optionals isIntel [ "kvm-intel" ];
    boot.extraModprobeConfig =
      if isAmd then "options kvm_amd nested=1" else "options kvm_intel nested=1";

    # Trust bridge network interface(s)
    networking.firewall.trustedInterfaces = [
      "virbr0"
      "br0"
    ];

    # For passthrough with VFI
    services.udev.extraRules = ''
      # Supporting VFIO
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
    '';
  };
}
