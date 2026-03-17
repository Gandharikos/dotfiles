{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.services.fwupd;
in
{
  options.my.services.fwupd = {
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
