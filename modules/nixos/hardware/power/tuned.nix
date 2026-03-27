{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (config.my) machine;
in
{
  config = mkIf (machine.type == "laptop") {

    services = {
      tlp.enable = mkForce false;
      tuned = {
        enable = true;

        # auto magically change the profile based on the battery charging state
        ppdSettings.main.battery_detection = true;
      };
    };
  };
}
