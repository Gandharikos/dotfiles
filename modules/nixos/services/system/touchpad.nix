{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my) machine;
in
{
  config = mkIf (machine.type == "laptop") {
    # Input settings for libinput
    services.libinput = {
      enable = true;

      # disable mouse acceleration for gaming
      mouse = {
        accelProfile = "flat";
        accelSpeed = "0";
        middleEmulation = false;
      };

      # touchpad settings
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        clickMethod = "clickfinger";
        horizontalScrolling = false;
        disableWhileTyping = true;
      };
    };
  };
}
