{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dot.profiles.headless;
in
{
  config = mkIf cfg.enable {
    # a headless system should not mount any removable media
    # without explicit user action
    services.udisks2.enable = lib.modules.mkForce false;
  };
}
