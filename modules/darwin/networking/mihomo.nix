{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.modules) mkIf mkOrder;
  inherit (lib.meta) getExe;
  cfg = config.my.networking.proxy;

  configDir = "${config.my.home}/.config/mihomo";
  uiDir = "${configDir}/ui";
  rawConfigFile = "${configDir}/config.secret.yaml";
  configFile = "${configDir}/config.yaml";
  mihomo' = getExe pkgs.mihomo;
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    environment.systemPackages =
      lib.optionals (cfg.mode == "service") [ pkgs.mihomo ]
      ++ lib.optionals (cfg.mode == "service" && cfg.enableWebui) [ pkgs.metacubexd ];

    homebrew.casks = lib.optionals (cfg.mode == "desktop") [ "clash-verge-rev" ];

    sops.secrets.mihomo_config = mkIf (cfg.mode == "service") {
      sopsFile = "${self}/secrets/services/mihomo.yaml";
      path = rawConfigFile;
      owner = config.my.name;
      group = "staff";
      mode = "0600";
    };

    # Launch daemon for mihomo (only if autoStart is enabled)
    launchd.daemons.mihomo = mkIf (cfg.mode == "service" && cfg.autoStart) {
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

    # sops-nix installs secrets in postActivation on Darwin. Run after that to
    # restore user ownership and render a derived config that can point Mihomo
    # at the packaged WebUI without modifying the encrypted source config.
    system.activationScripts.postActivation.text = mkIf (cfg.mode == "service") (
      mkOrder 2000 ''
        mkdir -p ${configDir}
        rm -f ${configFile}
        cat ${rawConfigFile} > ${configFile}
        ${lib.optionalString cfg.enableWebui ''
          mkdir -p ${uiDir}
          cp -R ${pkgs.metacubexd}/. ${uiDir}
          chown -R ${config.my.name}:staff ${uiDir}
          chmod -R u+rwX,go+rX ${uiDir}
          printf '\nexternal-ui: %s\n' '${uiDir}' >> ${configFile}
        ''}
        chown ${config.my.name}:staff ${configDir}
        chown ${config.my.name}:staff ${configFile}
        chmod 0755 ${configDir}
        chmod 0600 ${configFile}
      ''
    );
  };
}
