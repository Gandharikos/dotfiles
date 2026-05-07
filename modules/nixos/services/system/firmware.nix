{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.services.fwupd;
in
{
  options.dot.services.fwupd = {
    enable = mkEnableOption "Whether to enable the firmware updater for machine hardware";
  };

  config = mkIf cfg.enable {
    # firmware updater for machine hardware
    services.fwupd = {
      enable = true;
      daemonSettings.EspLocation = config.boot.loader.efi.efiSysMountPoint;
    };
  };
}
