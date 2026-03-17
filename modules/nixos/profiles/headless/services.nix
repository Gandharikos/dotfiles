{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  isHeadless = !config.my.gui.enable;
in
{
  config = mkIf isHeadless {
    # a headless system should not mount any removable media
    # without explicit user action
    services.udisks2.enable = lib.modules.mkForce false;
  };
}
