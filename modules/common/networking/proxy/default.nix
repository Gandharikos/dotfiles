{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    enum
    nullOr
    path
    ;
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.dot.networking.proxy;

  # NixOS passes the root-owned secret to the DynamicUser service with LoadCredential.
  # Darwin keeps the private Mihomo configuration in the user's home.
  proxyConfigPath =
    if isDarwin then
      "${config.dot.admin.homeDirectory}/.config/mihomo/config.yaml"
    else
      "/run/secrets/mihomo-config.yaml";
  proxyConfigOwner = if isDarwin then config.dot.primaryUser else "root";
  proxyConfigGroup = if isDarwin then "staff" else "root";
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
    enable = mkEnableOption "proxy backend (mihomo or sing-box)";
    autoStart = mkEnableOption "proxy auto start on boot (NixOS only)";

    backend = mkOption {
      type = enum [
        "mihomo"
        "sing-box"
      ];
      default = "mihomo";
      description = "Proxy backend to activate for this host.";
    };

    mihomo.configFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Runtime Mihomo configuration path; null uses the shared SOPS clash_config secret.";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.backend == "mihomo" && cfg.mihomo.configFile == null) {
      sops.secrets.proxy_config = {
        sopsFile = "${self}/secrets/services/clash.yaml";
        key = "clash_config";
        path = proxyConfigPath;
        owner = proxyConfigOwner;
        group = proxyConfigGroup;
        mode = proxyConfigMode;
      };
    })

    (mkIf (cfg.enable && cfg.backend == "sing-box" && cfg.singBox.configFile == null) {
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
