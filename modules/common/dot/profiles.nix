{ lib, ... }:
let
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.profiles = {
    minimal = {
      enable = mkEnableOption "minimal profile" // {
        default = false;
      };
    };
  };
}
