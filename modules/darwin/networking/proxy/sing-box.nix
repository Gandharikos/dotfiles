{
  lib,
  config,
  pkgs,
  proxyCommon,
  ...
}:
let
  cfg = config.dot.networking.proxy;
  inherit (lib) mkIf;
  configDir = "${config.dot.admin.homeDirectory}/.config/sing-box";
  generateConfig = proxyCommon.mkSingBoxGenerateConfig {
    name = "generate-sing-box-config";
    inherit pkgs;
    sourceConfigPath = config.sops.secrets.proxy_source_config.path;
    outputConfigPath = "${configDir}/config.json";
    outputNodesPath = "${configDir}/generated-outbounds.json";
    singBoxCfg = cfg.singBox;
  };
in
{
  config = mkIf (cfg.enable && cfg.backend == "sing-box") {
    environment.systemPackages = [ pkgs.sing-box ];

    system.activationScripts.postActivation.text = lib.mkAfter ''
      install -d -m 0700 -o ${config.dot.primaryUser} -g staff ${configDir}
      ${lib.getExe generateConfig}
      chown ${config.dot.primaryUser}:staff ${configDir}/config.json
      chmod 0600 ${configDir}/config.json
    '';
  };
}
