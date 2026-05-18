{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.my.gui.apps.clash;

  # Enable when GUI is enabled and clash-verge is enabled
  # Note: This is just the GUI frontend. The mihomo core service is configured separately at the NixOS level.
  enable = osConfig.dot.gui.enable && cfg.enable;

  # Verge.yaml configuration using Nix attrset
  vergeConfig = {
    # Enable system proxy
    enable_system_proxy = true;

    # Theme settings
    theme_mode = "auto";

    # Language
    language = "en";

    # Traffic graph
    enable_traffic_graph = true;

    # Auto launch (controlled by dot.networking.proxy.autoStart at system level)
    enable_auto_launch = false;

    # Tun mode is handled by the mihomo service
    enable_tun_mode = false;
  };

  yamlFormat = pkgs.formats.yaml { };
in
{
  options.my.gui.apps.clash = {
    enable = mkEnableOption "Clash Verge GUI" // {
      default = osConfig.dot.gui.enable && isLinux;
    };
  };

  config = mkIf enable {
    home = {
      # Install Clash Verge as a user application
      packages = with pkgs; [ clash-verge-rev ];

      # Generate verge.yaml from Nix configuration
      # Note: The .config/clash-verge directory is created by sops for config.yaml
      file.".config/clash-verge/verge.yaml".source = yamlFormat.generate "verge.yaml" vergeConfig;
    };
  };
}
