{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;

  cfg = osConfig.programs.clash-verge;
  proxy = osConfig.dot.networking.proxy;
  enable = proxy.clashVerge.enabledUser == config.home.username;

  inherit (cfg) package;
  dataDir = "${config.xdg.dataHome}/io.github.clash-verge-rev.clash-verge-rev";

  # Verge.yaml configuration using Nix attrset
  vergeConfig = {
    enable_system_proxy = !cfg.tunMode;

    # Theme settings
    theme_mode = "auto";

    # Language
    language = "en";

    # Traffic graph
    enable_traffic_graph = true;

    # Home Manager manages the XDG autostart entry instead of the GUI.
    enable_auto_launch = false;

    enable_tun_mode = cfg.tunMode;
  };

  yamlFormat = pkgs.formats.yaml { };
  vergeConfigFile = yamlFormat.generate "verge.yaml" vergeConfig;
in
{
  config = mkIf enable {
    xdg.configFile."autostart/clash-verge.desktop" = mkIf proxy.autoStart {
      source = "${package}/share/applications/clash-verge.desktop";
    };

    home = {
      # Clash Verge writes this file itself; a read-only store symlink breaks GUI settings.
      activation.clashVergeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg dataDir}
        if [[ -e ${lib.escapeShellArg "${dataDir}/verge.yaml"} ]]; then
          run ${lib.getExe pkgs.yq-go} --inplace '. *= load("${vergeConfigFile}")' \
            ${lib.escapeShellArg "${dataDir}/verge.yaml"}
        else
          run install -m 0600 ${vergeConfigFile} ${lib.escapeShellArg "${dataDir}/verge.yaml"}
        fi
      '';
    };
  };
}
