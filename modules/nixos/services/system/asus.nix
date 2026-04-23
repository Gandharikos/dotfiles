{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.services.asus;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in
{
  options.my.services.asus = {
    enable = mkEnableOption "Enable ASUS laptop support";
  };

  config = mkIf cfg.enable {
    # ASUS laptop control utilities
    # Provides support for:
    # - Keyboard backlight control
    # - Fan profiles
    # - Battery charge limit
    # - AniMe Matrix display (on supported models)
    services.asusd.enable = true;

    # asusd.service uses ReadWritePaths=/etc/asusd/ with ProtectSystem=strict,
    # which requires the directory to exist before systemd sets up the mount namespace.
    # On ephemeral-root systems this directory won't exist without this rule.
    systemd.tmpfiles.rules = [ "d /etc/asusd 0755 root root -" ];

    # Ensure tmpfiles creates /etc/asusd before systemd applies ReadWritePaths
    # for asusd.service, otherwise the unit fails early with 226/NAMESPACE.
    systemd.services.asusd = {
      after = [ "systemd-tmpfiles-setup.service" ];
      requires = [ "systemd-tmpfiles-setup.service" ];
    };

    # Persist asusd config (fan profiles, keyboard backlight, etc.) across reboots.
    # Only takes effect when preservation.enable = true.
    preservation.preserveAt."/persist".directories = [ "/etc/asusd" ];

    # Graphics switching for dual-GPU ASUS laptops
    # Manages NVIDIA/AMD discrete GPU power
    # DISABLED: Causing kernel panic on boot
    # services.supergfxd.enable = true;

    # Add asusctl CLI and GUI tools to system packages
    environment.systemPackages = with pkgs; [
      asusctl # CLI control tool
      # ROG Control Center GUI (uncomment if needed)
      # rog-control-center
    ];
  };
}
