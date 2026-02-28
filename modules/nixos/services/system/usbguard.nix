{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.services.usbguard;
in {
  options.my.services.usbguard = {
    enable =
      mkEnableOption "Enable USBGuard"
      // {
        default = config.my.security.enable;
      };
  };
  config = mkIf cfg.enable {
    services.usbguard = {
      IPCAllowedUsers = ["root" "${config.my.name}"];
      presentDevicePolicy = "allow";
      rules = ''
        allow with-interface equals { 08:*:* }

        # Reject devices with suspicious combination of interfaces
        reject with-interface all-of { 08:*:* 03:00:* }
        reject with-interface all-of { 08:*:* 03:01:* }
        reject with-interface all-of { 08:*:* e0:*:* }
        reject with-interface all-of { 08:*:* 02:*:* }
      '';
    };

    environment.systemPackages = [pkgs.usbguard];
  };
}
