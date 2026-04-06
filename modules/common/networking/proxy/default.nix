{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.my.networking.proxy;

  proxyConfigPath =
    if isDarwin || config.my.gui.enable then
      "${config.my.home}/.config/clash-verge/config.yaml"
    else
      "/var/lib/mihomo/config.yaml";
  proxyConfigOwner = if isDarwin || config.my.gui.enable then config.my.name else "mihomo";
  proxyConfigGroup =
    if isDarwin then
      "staff"
    else if config.my.gui.enable then
      "users"
    else
      "mihomo";
  proxyConfigMode = if isDarwin || config.my.gui.enable then "0600" else "0400";

  proxySourceConfigPath =
    if isDarwin then
      "${config.my.home}/.config/sing-box/clash.yaml"
    else
      "/run/secrets/proxy-source-config.yaml";
  proxySourceConfigOwner = if isDarwin then config.my.name else "root";
  proxySourceConfigGroup = if isDarwin then "staff" else "root";
  proxySourceConfigMode = if isDarwin then "0600" else "0400";
in
{
  imports = lib.my.scanPaths ./.;

  options.my.networking.proxy = {
    enable = mkEnableOption "proxy service (mihomo or sing-box)" // {
      default = true;
    };

    autoStart = mkEnableOption "auto start proxy on boot (NixOS only)" // {
      default = false;
    };

    backend = mkOption {
      type = enum [
        "mihomo"
        "sing-box"
      ];
      default = "mihomo";
      description = "Proxy backend to activate for this host.";
    };
  };

  config = mkMerge [
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
