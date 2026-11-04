{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum nullOr str;
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  cfg = config.dot.networking.proxy;

  # On NixOS: mihomo runs as a system service, config goes to /var/lib/mihomo/
  # On Darwin: clash-verge includes mihomo core, config goes to user's home
  proxyConfigPath =
    if isDarwin then
      "${config.dot.admin.homeDirectory}/.config/clash-verge/config.yaml"
    else
      "/var/lib/mihomo/config.yaml";
  proxyConfigOwner = if isDarwin then config.dot.primaryUser else "mihomo";
  proxyConfigGroup = if isDarwin then "staff" else "mihomo";
  proxyConfigMode = if isDarwin then "0600" else "0400";

  proxySourceConfigPath =
    if isDarwin then
      "${config.dot.admin.homeDirectory}/.config/sing-box/clash.yaml"
    else
      "/run/secrets/proxy-source-config.yaml";
  proxySourceConfigOwner = if isDarwin then config.dot.primaryUser else "root";
  proxySourceConfigGroup = if isDarwin then "staff" else "root";
  proxySourceConfigMode = if isDarwin then "0600" else "0400";
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.networking.proxy = {
    enable = mkEnableOption "proxy backend (mihomo, sing-box or Clash Verge)";
    autoStart = mkEnableOption "proxy auto start on boot, or desktop login for Clash Verge (NixOS only)";

    backend = mkOption {
      type = enum (
        [
          "mihomo"
          "sing-box"
        ]
        ++ lib.optionals config.dot.gui.enable [ "clash-verge" ]
      );
      default = "mihomo";
      description = "Proxy backend to activate for this host.";
    };

    clashVerge.enabledUser = mkOption {
      type = nullOr str;
      internal = true;
      readOnly = true;
      default =
        if isLinux && config.dot.gui.enable && cfg.enable && cfg.backend == "clash-verge" then
          config.dot.primaryUser
        else
          null;
      description = "User running the desktop-managed Clash Verge backend, or null when inactive.";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.backend == "clash-verge") {
      assertions = [
        {
          assertion = !isDarwin && config.dot.gui.enable;
          message = "The Clash Verge proxy backend requires a NixOS desktop.";
        }
      ];
    })

    (mkIf (cfg.enable && cfg.backend == "mihomo") {
      sops.secrets.proxy_config = {
        sopsFile = "${self}/secrets/services/clash.yaml";
        key = "clash_config";
        path = proxyConfigPath;
        owner = proxyConfigOwner;
        group = proxyConfigGroup;
        mode = proxyConfigMode;
      };
    })

    (mkIf (cfg.enable && cfg.backend == "sing-box") {
      sops.secrets.proxy_source_config = {
        sopsFile = "${self}/secrets/services/clash.yaml";
        key = "clash_config";
        path = proxySourceConfigPath;
        owner = proxySourceConfigOwner;
        group = proxySourceConfigGroup;
        mode = proxySourceConfigMode;
      };
    })
  ];
}
