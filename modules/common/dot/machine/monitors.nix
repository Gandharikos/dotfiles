{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types)
    str
    listOf
    submodule
    float
    ;
in
{
  options.dot.machine.monitors = mkOption {
    type = listOf (submodule {
      options = {
        name = mkOption {
          type = str;
          default = "DP-1";
          description = "The name of the monitor";
        };
        resolution = mkOption {
          type = str;
          default = "3840x2160@60";
          description = "The resolution of the monitor";
        };
        position = mkOption {
          type = str;
          default = "0x0";
          description = "The position of the monitor";
        };
        scale = mkOption {
          type = float;
          default = 1;
          description = "The scale of the monitor";
        };
      };
    });
    default = [
      {
        name = "DP-1";
        resolution = "highres";
        position = "auto-left";
        scale = 2.0;
      }
      {
        name = "DP-2";
        resolution = "highres";
        position = "auto-right";
        scale = 2.0;
      }
    ];
    description = ''
      this does not affect any drivers and such, it is only necessary for
      declaring things like monitors in window manager configurations
      you can avoid declaring this, but I'd rather if you did declare
    '';
  };
}
