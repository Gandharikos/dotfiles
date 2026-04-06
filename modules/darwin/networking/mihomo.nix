{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  cfg = config.my.networking.proxy;

  configDir = "${config.my.home}/.config/mihomo";
  configFile = "${configDir}/config.yaml";
  mihomo' = getExe pkgs.mihomo;
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    # Install mihomo and the default GUI client when enabled
    environment.systemPackages = [
      pkgs.mihomo
    ]
    ++ lib.optionals cfg.enableWebui [ pkgs.metacubexd ]
    ++ lib.optionals cfg.enableGui [ pkgs.clash-verge-rev ];

    sops.secrets.mihomo_config = {
      sopsFile = "${self}/secrets/services/mihomo.yaml";
      path = configFile;
      owner = config.my.name;
      group = "staff";
      mode = "0600";
    };

    # Launch daemon for mihomo (only if autoStart is enabled)
    launchd.daemons.mihomo = mkIf cfg.autoStart {
      serviceConfig = {
        ProgramArguments = [
          mihomo'
          "-d"
          configDir
        ];
        Label = "com.mihomo.proxy";
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/log/mihomo.log";
        StandardErrorPath = "/var/log/mihomo-error.log";
        WorkingDirectory = "/tmp";
      };
    };

    # Create initial config directory
    system.activationScripts.mihomo-setup = {
      text = ''
        mkdir -p ${configDir}
        chown ${config.my.name}:staff ${configDir}
      '';
    };
  };
}
