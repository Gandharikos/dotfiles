{ lib, ... }:
let
  inherit (lib.my) scanPaths;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) str;
in
{
  imports = scanPaths ./.;

  options.my.theme.general = {
    transparent = mkEnableOption "Enable tmux transparent" // {
      default = true;
    };
    pad = {
      left = mkOption {
        type = str;
        default = "";
        description = "The left padding of status bar";
      };
      right = mkOption {
        type = str;
        default = "";
        description = "The right padding of status bar";
      };
    };
  };
}
