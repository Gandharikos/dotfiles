{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.my) isx86Linux;
  cfg = config.my.video;
in
{
  options.my.video = {
    enable = mkEnableOption "Does the device allow for graphical programs";

    benchmarking.enable = mkEnableOption "Enable benchmarking tools";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = isx86Linux pkgs;
      };
    }

    # benchmarking tools
    (mkIf cfg.benchmarking.enable {
      environment.systemPackages = [
        pkgs.mesa-demos
        pkgs.glmark2
      ];
    })
  ]);
}
