{
  lib,
  config,
  pkgs,
  proxyCommon,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib) mkIf mkForce;
  singBoxCfg = cfg.singBox;
  baseSettings = proxyCommon.mkSingBoxSettings {
    inherit pkgs singBoxCfg;
  };
in
{
  config = mkIf (cfg.enable && cfg.backend == "sing-box") {
    services.sing-box = {
      enable = true;
      settings = lib.recursiveUpdate baseSettings singBoxCfg.settings;
    };

    systemd.services.sing-box = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else mkForce [ ];
    };
  };
}
