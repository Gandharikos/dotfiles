{lib, ...}: let
  inherit (lib.modules) mkDefault;
in {
  systemd = {
    # systemd OOMd
    # Fedora enables these options by default. See the 10-oomd-* files here:
    # https://src.fedoraproject.org/rpms/systemd/tree/acb90c49c42276b06375a66c73673ac3510255
    oomd = {
      enable = mkDefault true;
      enableRootSlice = true;
      enableUserSlices = true;
      enableSystemSlice = true;
      settings.OOM = {
        "DefaultMemoryPressureDurationSec" = "20s";
      };
    };

    services.nix-daemon.serviceConfig.OOMDScoreAdjust = mkDefault 350;

    tmpfiles.settings."10-oomd-root" = {
      # Enables storing of the kernel log (including stack trace) into pstore upon a panic or crash.
      "/sys/module/kernel/parameters/crash_kexec_post_notifiers".w = {
        argument = "Y";
      };

      # Enables storing of the kernel log upon a normal shutdown (shutdown, reboot, halt).
      "/sys/module/printk/parameters/always_kmsg_dump".w = {
        argument = "N";
      };
    };
  };
}
