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
        "sops-install-secrets.service"
      ];
      requires = [ "sops-install-secrets.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStartPre = mkIf (cfg.singBox.configFile == null) (mkForce "+${lib.getExe generateConfig}");
        # settings = {} otherwise makes the upstream unit read /etc/sing-box,
        # not the runtime configuration produced by either generator.
        ExecStart = mkForce [
          ""
          "${lib.getExe config.services.sing-box.package} -D /var/lib/sing-box -c ${
            lib.escapeShellArg (
              if cfg.singBox.configFile == null then "/run/sing-box/config.json" else cfg.singBox.configFile
            )
          } run"
        ];
      };
      wantedBy = if cfg.autoStart then [ "multi-user.target" ] else mkForce [ ];
    };
  };
}
