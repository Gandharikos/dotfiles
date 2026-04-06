{
  lib,
  config,
  pkgs,
  proxyCommon,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib) mkIf;
  singBoxCfg = cfg.singBox;
  baseSettings = proxyCommon.mkSingBoxSettings {
    inherit pkgs singBoxCfg;
  };
in
{
  config = mkIf (cfg.enable && cfg.backend == "sing-box") {
    environment.etc."sing-box/config.json".text = builtins.toJSON (
      lib.recursiveUpdate baseSettings singBoxCfg.settings
    );

    environment.systemPackages = [ pkgs.sing-box ];
  };
}
