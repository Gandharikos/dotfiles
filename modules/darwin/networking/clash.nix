{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  guiEnabled = config.my.gui.enable;

  # Config paths
  clashVergeConfigDir = "${config.my.home}/.config/clash-verge";
  mihomoConfigDir = "${config.my.home}/.config/mihomo";
  configFile =
    if guiEnabled then "${clashVergeConfigDir}/config.yaml" else "${mihomoConfigDir}/config.yaml";
in
{
  config = mkIf cfg.enable (
    lib.mkMerge [
      # Common: decrypt secrets
      {
        sops.secrets.clash_config = {
          sopsFile = "${self}/secrets/services/clash.yaml";
          path = configFile;
          owner = config.my.name;
          group = "staff";
          mode = "0600";
        };
      }

      # GUI mode: use Clash Verge
      (mkIf guiEnabled {
        homebrew.casks = [ "clash-verge-rev" ];
      })

      # Non-GUI mode: use mihomo core + WebUI
      (mkIf (!guiEnabled) {
        environment.systemPackages = with pkgs; [
          mihomo
          metacubexd
        ];

        # Launch daemon for mihomo
        launchd.daemons.mihomo = mkIf cfg.autoStart {
          serviceConfig = {
            ProgramArguments = [
              "${getExe pkgs.mihomo}"
              "-d"
              mihomoConfigDir
            ];
            Label = "com.mihomo.proxy";
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/var/log/mihomo.log";
            StandardErrorPath = "/var/log/mihomo-error.log";
            WorkingDirectory = "/tmp";
          };
        };
      })
    ]
  );
}
