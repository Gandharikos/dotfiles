{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
  inherit (lib.modules) mkIf;
in {
  config = mkIf cfg.enable {
    services = {
      # Thumbnail support for images
      tumbler.enable = true;
      # Mount, trash, and other functionalities
      gvfs.enable = true;
      # storage daemon required for udiskie auto-mount
      udisks2.enable = true;

      dbus = {
        enable = true;
        # Use the faster dbus-broker instead of the classic dbus-daemon
        implementation = "broker";

        packages = builtins.attrValues {inherit (pkgs) dconf gcr udisks2;};
      };
    };
  };
}
