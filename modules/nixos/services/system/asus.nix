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

    # Graphics switching for dual-GPU ASUS laptops
    # Manages NVIDIA/AMD discrete GPU power
    services.supergfxd.enable = true;

    # Add asusctl CLI and GUI tools to system packages
    environment.systemPackages = with pkgs; [
      asusctl # CLI control tool
      # ROG Control Center GUI (uncomment if needed)
      # rog-control-center
    ];
  };
}
