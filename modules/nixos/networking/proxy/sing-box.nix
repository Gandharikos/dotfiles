{
  lib,
  config,
  pkgs,
  proxyCommon,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (lib) mkIf mkForce;
  generateConfig = proxyCommon.mkSingBoxGenerateConfig {
    name = "generate-sing-box-config";
    inherit pkgs;
    sourceConfigPath = config.sops.secrets.proxy_source_config.path;
    outputConfigPath = "/run/sing-box/config.json";
    outputNodesPath = "/run/sing-box/generated-outbounds.json";
    singBoxCfg = cfg.singBox;
  };
in
{
  config = mkIf (cfg.enable && cfg.backend == "sing-box") {
    services.sing-box = {
      enable = true;
      settings = { };
    };

    systemd.services.sing-box = {
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      requires = [ "sops-nix.service" ];
      wants = [ "network-online.target" ];
      serviceConfig.ExecStartPre = mkForce "+${lib.getExe generateConfig}";
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else mkForce [ ];
    };
  };
}
